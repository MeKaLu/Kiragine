// -----------------------------------------
// |           Kiragine 1.1.1              |
// -----------------------------------------
// Copyright © 2020-2020 Mehmet Kaan Uluç <kaanuluc@protonmail.com>
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would
//    be appreciated but is not required.
//
// 2. Altered source versions must be plainly marked as such, and must not
//    be misrepresented as being the original software.
//
// 3. This notice may not be removed or altered from any source
//    distribution.

const std = @import("std");

const math = @import("kira/math/common.zig");

const UniqueFixedList = @import("kira/utils.zig").UniqueFixedList;
usingnamespace @import("sharedtypes.zig");

pub fn ObjectGeneric(comptime maxtag: u64, comptime complist: type) type {
    return struct {
        const Self = @This();
        pub const ComponentList = complist;
        pub const MaxTag = maxtag;
        pub const FixedList = UniqueFixedList(u64, MaxTag);

        id: u64 = undefined,
        tags: FixedList = undefined,
        components: ComponentList = undefined,

        /// Does the tag exists?
        pub fn hasTag(self: Self, tag: u64) bool {
            return self.tags.isExists(tag);
        }

        /// Clears the tags
        pub fn clearTags(self: *Self) void {
            self.tags.clear();
        }

        pub fn addTags(self: *Self, tags: [MaxTag]u64) Error!void {
            var i: u64 = 0;
            while (i < MaxTag) : (i += 1) {
                _ = try self.tags.insert(tags[i]);
            }
        }

        /// Adds a component to the object
        pub fn addComponent(self: *Self, comptime comptype: type, comptime compname: []const u8, component: comptype, tag: u64) Error!void {
            comptime {
                if (!@hasField(ComponentList, compname)) @compileError("Unknown component type " ++ compname ++ "!");
            }

            _ = try self.tags.insert(tag);
            @field(self.components, compname) = component;
        }

        /// Removes a component to the object
        pub fn removeComponent(self: *Self, tag: u64) Error!void {
            try self.tags.remove(tag);
        }

        /// Gets a component to the object
        pub fn getComponent(self: Self, comptime comptype: type, comptime compname: []const u8, tag: u64) Error!comptype {
            comptime {
                if (!@hasField(ComponentList, compname)) @compileError("Unknown component type " ++ compname ++ "!");
            }

            if (!self.tags.isExists(tag)) return Error.Unknown;
            return @field(self.components, compname);
        }

        /// Replaces a component
        pub fn replaceComponent(self: *Self, comptime comptype: type, comptime compname: []const u8, component: comptype, tag: u64) Error!void {
            comptime {
                if (!@hasField(ComponentList, compname)) @compileError("Unknown component type " ++ compname ++ "!");
            }
            if (!self.tags.isExists(tag)) return Error.Unknown;
            @field(self.components, compname) = component;
        }
    };
}

pub fn WorldGeneric(comptime max_object: u64, comptime max_filter: u64, comptime object: type) type {
    return struct {
        const Self = @This();
        pub const Object = object;
        pub const MaxObject = max_object;
        pub const MaxFilter = max_filter;

        objectlist: [MaxObject]Object = undefined,
        objectidlist: UniqueFixedList(u64, MaxObject) = undefined,

        filteredlist: [MaxObject]*Object = undefined,
        filteredidlist: UniqueFixedList(u64, MaxObject) = undefined,

        filters: UniqueFixedList(u64, MaxFilter) = undefined,

        /// Does the object exists?
        pub fn hasObject(self: Self, id: u64) bool {
            return self.objectidlist.isExists(id);
        }

        /// Does the object exists in the filters?
        pub fn hasObjectInFilters(self: Self, id: u64) bool {
            return self.filteredidlist.isExists(id);
        }

        /// Does the filter exists?
        pub fn hasFilter(self: Self, filter: u64) bool {
            return self.filters.isExists(filter);
        }

        /// Does the filters exists?
        pub fn hasFilters(self: *Self, comptime max: u64, tags: [max]u64) bool {
            var i: u64 = 0;
            while (i < max) : (i += 1) {
                if (!self.filters.isExists(tags[i])) return false;
            }
            return true;
        }

        /// Clears the objects
        pub fn clearObjects(self: *Self) void {
            self.objectidlist.clear();
            self.filteredidlist.clear();

            self.objectlist = undefined;
            self.filteredlist = undefined;
        }

        /// Clears the filtered objects 
        pub fn clearFilteredObjects(self: *Self) void {
            self.filteredidlist.clear();
            self.filteredlist = undefined;
        }

        /// Clears the filters        
        pub fn clearFilters(self: *Self) void {
            self.filters.clear();
        }

        /// Adds an object
        pub fn addObject(self: *Self, obj: Object) Error!void {
            if (self.objectidlist.isExists(obj.id)) return Error.Duplicate;
            const i = try self.objectidlist.insert(obj.id);
            self.objectlist[i] = obj;
        }

        /// Force pushes the object in to the filtered list
        pub fn forceObjectToFilter(self: *Self, id: u64) Error!void {
            if (!self.objectidlist.isExists(id)) return Error.Unknown;
            if (self.filteredidlist.isExists(id)) return Error.Duplicate;

            const index = try self.objectidlist.getIndex(id);
            var ptr = &self.objectlist[index];
            const i = try self.filteredidlist.insert(id);
            self.filteredlist[i] = ptr;
        }

        /// Adds a filter
        pub fn addFilter(self: *Self, filter: u64) Error!void {
            _ = try self.filters.insert(filter);
        }

        /// Filter the objects
        pub fn filterObjects(self: *Self) Error!void {
            self.clearFilteredObjects();
            var i: u64 = 0;
            while (i < Self.MaxObject) : (i += 1) {
                if (self.objectidlist.items[i].is_exists) {
                    var obj = &self.objectlist[i];
                    var j: u64 = 0;
                    var yes = true;
                    while (j < Self.MaxFilter) : (j += 1) {
                        if (self.filters.items[j].is_exists) {
                            const filter = self.filters.items[j].data;
                            if (!obj.hasTag(filter)) yes = false;
                        }
                    }
                    if (yes) {
                        try self.forceObjectToFilter(obj.id);
                    }
                }
            }
            if (self.filteredidlist.count == 0) return Error.FailedToAdd;
        }
    };
}
