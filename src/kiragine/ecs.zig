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

const UniqueList = @import("kira/utils.zig").UniqueList;
usingnamespace @import("sharedtypes.zig");

const drawRectangleRotated = @import("renderer.zig").drawRectangleRotated;
const Rectangle = @import("renderer.zig").Rectangle;

const hash = std.hash.Wyhash.hash;

pub fn Components(seed: u64, comptime prefix: []const u8) type {
    return struct {
        pub const Transform = struct {
            pub const tag = hash(seed, prefix ++ "TransformComponent");
            position: Vec2f = undefined,
            size: Vec2f = undefined,
            origin: Vec2f = undefined,
            colour: Colour = undefined,
            /// In degrees
            rotation: f32 = 0,
        };
        pub const Alive = struct {
            pub const tag = hash(seed, prefix ++ "AliveComponent");
            is_it: bool = false,
        };

        transform: Transform = undefined,
        is_alive: Alive = undefined,
    };
}

pub const Logics = struct {
    /// Draws a rectangle, requires Transform and Alive
    pub fn drawRectangle(comptime systype: type, self: *systype, comptime transform: type, comptime alive: type) Error!void {
        var i: u64 = 0;
        while (i < self.filtered_list.count) : (i += 1) {
            if (!self.filtered_list.items[i].is_exists) continue;
            const ent = self.filtered_list.items[i].data;

            const is_alive = try ent.getComponent(alive, "is_alive", alive.tag);
            if (is_alive.is_it) {
                const tr = try ent.getComponent(transform, "transform", transform.tag);
                const colour = tr.colour;
                const rot = math.deg2radf(tr.rotation);
                const rect = Rectangle{ .x = tr.position.x, .y = tr.position.y, .width = tr.size.x, .height = tr.size.y };
                try drawRectangleRotated(rect, tr.origin, rot, colour);
            }
        }
    }
};

pub fn EntityGeneric(comptime complisttype: type) type {
    return struct {
        const Self = @This();
        pub const ComponentList = complisttype;
        id: u64 = undefined,

        components: ComponentList = undefined,
        tags: UniqueList(u64) = undefined,

        /// Initializes the entity
        pub fn init(self: *Self, alloc: *std.mem.Allocator) !void {
            self.tags = try UniqueList(u64).init(alloc, 10);
        }

        /// Deinitializes the entity
        pub fn deinit(self: *Self) void {
            self.tags.deinit();
        }

        /// Clears the tags within the entity
        pub fn clearTags(self: *Self) void {
            self.tags.clear();
        }

        /// Requires the specific component
        pub fn requireFilter(self: *Self, tag: u64) bool {
            return self.tags.isExists(tag);
        }

        /// Requires filters
        pub fn requireFilters(self: *Self, comptime max: u64, tags: [max]u64) bool {
            var i: u64 = 0;
            while (i < max) : (i += 1) {
                if (!self.tags.isExists(tags[i])) return false;
            }
            return true;
        }

        /// Adds a component to the entity
        pub fn addComponent(self: *Self, comptime comptype: type, comptime compname: []const u8, component: comptype, tag: u64) !void {
            comptime {
                if (!@hasField(ComponentList, compname)) @compileError("Unknown component type " ++ compname ++ "!");
            }

            try self.tags.insert(tag, true);
            @field(self.components, compname) = component;
        }

        /// Removes a component to the entity
        pub fn removeComponent(self: *Self, tag: u64) Error!void {
            try self.tags.remove(tag);
        }

        /// Gets a component to the entity
        pub fn getComponent(self: Self, comptime comptype: type, comptime compname: []const u8, tag: u64) Error!comptype {
            comptime {
                if (!@hasField(ComponentList, compname)) @compileError("Unknown component type " ++ compname ++ "!");
            }

            if (!self.tags.isExists(tag)) return Error.Unknown;
            return @field(self.components, compname);
        }

        /// Replaces a component
        pub fn replaceComponent(self: *Self, comptime comptype: type, comptime compname: []const u8, component: comptype, tag: u64) !void {
            comptime {
                if (!@hasField(ComponentList, compname)) @compileError("Unknown component type " ++ compname ++ "!");
            }
            if (!self.tags.isExists(tag)) return Error.Unknown;
            @field(self.components, compname) = component;
        }
    };
}

pub fn SystemGeneric(comptime entitytype: type) type {
    return struct {
        const Self = @This();
        pub const Entity = entitytype;

        filtered_list: UniqueList(*Entity) = undefined,
        filter_tags: UniqueList(u64) = undefined,
        entites: UniqueList(*Entity) = undefined,

        /// Initializes the system
        pub fn init(self: *Self, alloc: *std.mem.Allocator) !void {
            self.filter_tags = try UniqueList(u64).init(alloc, 10);
            self.filtered_list = try UniqueList(*Entity).init(alloc, 10);
            self.entites = try UniqueList(*Entity).init(alloc, 100);
        }

        /// Deinitializes the system
        pub fn deinit(self: *Self) void {
            self.entites.deinit();
            self.filtered_list.deinit();
            self.filter_tags.deinit();
        }

        /// Clears the filters
        pub fn clearFilter(self: *Self) void {
            self.filter_tags.clear();
            self.filtered_list.clear();
        }

        /// Clears the entites
        pub fn clearEntites(self: *Self) void {
            self.entites.clear();
        }

        /// Is entity filtered?
        pub fn hasFiltered(self: Self, ent: Entity) bool {
            return self.filtered_list.isExists(ent);
        }

        /// Is entity exists?
        pub fn hasEntity(self: Self, ent: Entity) bool {
            return self.entites.isExists(ent);
        }

        /// Adds a filter
        pub fn addFilter(self: *Self, tag: u64) !void {
            try self.filter_tags.insert(tag, true);
        }

        /// Adds filters
        pub fn addFilters(self: *Self, comptime max: u64, tags: [max]u64) !void {
            var i: u64 = 0;
            while (i < max) : (i += 1) {
                try self.filter_tags.insert(tags[i], true);
            }
        }

        /// Require a filter
        pub fn requireFilter(self: *Self, tag: u64) bool {
            if (!self.filter_tags.isExists(tag)) return false;
            return true;
        }

        /// Requires filters
        pub fn requireFilters(self: *Self, comptime max: u64, tags: [max]u64) bool {
            var i: u64 = 0;
            while (i < max) : (i += 1) {
                if (!self.filter_tags.isExists(tags[i])) return false;
            }
            return true;
        }

        /// Updates the filters, gets the entities with requires specific filters
        pub fn updateFilters(self: *Self, comptime max: u64) !void {
            var i: u64 = 0;
            while (i < self.entites.count) : (i += 1) {
                if (self.entites.items[i].is_exists) {
                    // A dirty hack
                    var ent = self.entites.items[i].data;
                    const ar = ent.tags.convertToArray(u64, max);
                    const res = ent.requireFilters(max, ar);
                    if (res) {
                        try self.filtered_list.insert(ent, true);
                    }
                }
            }
            if (self.filtered_list.count == 0) return Error.FailedToAdd;
        }

        /// Add an entity
        pub fn addEntity(self: *Self, ent: *Entity) !void {
            try self.entites.insert(ent, true);
        }

        /// Remove the entity
        pub fn removeEntity(self: *Self, ent: *Entity) Error!void {
            try self.entites.remove(ent);
        }

        /// Get an entity ptr
        pub fn getEntity(self: Self, id: u64) Error!*Entity {
            var i: u64 = 0;
            while (i < self.entites.count) : (i += 1) {
                if (self.entites.items[i].is_exists and self.entites.items[i].data.id == id) {
                    return self.entites.items[i].data;
                }
            }
            return Error.Unknown;
        }
    };
}
