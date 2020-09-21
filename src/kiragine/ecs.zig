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

usingnamespace @import("sharedtypes.zig");
usingnamespace @import("kira/log.zig");

pub const invalid = 0;

pub fn EntityGeneric(comptime complisttype: type, maxtags: u64) type {
    return struct {
        const Self = @This();
        pub const ComponentList = complisttype;
        pub const max_tags = maxtags;
        id: u64 = invalid,

        components: ComponentList = undefined,
        tags: [max_tags]u64 = undefined,

        pub fn clearTags(self: *Self) void {
            var i: u64 = 0;
            while (i < max_tags) : (i += 1) {
                self.tags[i] = invalid;
            }
        }

        pub fn has(self: Self, tag: u64) bool {
            var i: u64 = 0;
            while (i < max_tags) : (i += 1) {
                if (self.tags[i] == tag) return true;
            }
            return false;
        }

        pub fn hasThem(self: Self, tags: [max_tags]u64) bool {
            var i: u64 = 0;
            var yes = true;

            while (i < max_tags) : (i += 1) {
                if (!self.has(tags[i])) {
                    yes = false;
                    break;
                }
            }
            return yes;
        }

        pub fn addComponentPtr(self: *Self, comptime comptype: type, comptime compname: []const u8, component: *comptype, tag: u64) Error!void {
            comptime {
                if (!@hasField(ComponentList, compname)) @compileError("Unknown component type " ++ compname ++ "!");
            }
            if (self.has(tag)) return Error.Duplicate;
            var i: u64 = 0;
            while (i < max_tags) : (i += 1) {
                if (self.tags[i] == invalid) {
                    self.tags[i] = tag;
                    @field(self.components, compname) = component;
                    return;
                }
            }
            return Error.FailedToAdd;
        }

        pub fn addComponent(self: *Self, comptime comptype: type, comptime compname: []const u8, component: comptype, tag: u64) Error!void {
            comptime {
                if (!@hasField(ComponentList, compname)) @compileError("Unknown component type " ++ compname ++ "!");
            }
            if (self.has(tag)) return Error.Duplicate;
            var i: u64 = 0;
            while (i < max_tags) : (i += 1) {
                if (self.tags[i] == invalid) {
                    self.tags[i] = tag;
                    @field(self.components, compname) = component;
                    return;
                }
            }
            return Error.FailedToAdd;
        }
    };
}

pub fn SystemGeneric(maxentity: u64, comptime entitytype: type) type {
    return struct {
        const Self = @This();
        pub const max_entity = maxentity;
        pub const Entity = entitytype;

        filtered_list: [max_entity]*Entity = undefined,
        filtered_count: u64 = 0,

        entites: [max_entity]Entity = undefined,

        proc: ?fn (self: *Self) anyerror!void = null,

        fn pushToTheFiltered(self: *Self, ent: *Entity) void {
            self.filtered_list[self.filtered_count] = ent;
            self.filtered_count += 1;
        }

        pub fn hasEntity(self: *Self, id: u64) bool {
            var i: u64 = 0;
            while (i < Self.max_entity) : (i += 1) {
                if (self.entites[i].id == id) {
                    return true;
                }
            }
            return false;
        }

        pub fn filter(self: *Self, tags: [Entity.max_tags]u64) Error!void {
            var i: u64 = 0;
            while (i < Self.max_entity) : (i += 1) {
                if (self.entites[i].id == invalid) continue;

                if (self.entites[i].hasThem(tags)) {
                    self.pushToTheFiltered(&self.entites[i]);
                }
            }
        }

        pub fn clearFilter(self: *Self) void {
            self.filtered_count = 0;
            self.filtered_list = undefined;
        }

        pub fn addEntity(self: *Self, ent: Entity) Error!void {
            if (self.hasEntity(ent.id)) return Error.Duplicate;
            var i: u64 = 0;
            while (i < Self.max_entity) : (i += 1) {
                if (self.entites[i].id == invalid) {
                    self.entites[i] = ent;
                    return;
                }
            }
            return Error.Unknown;
        }
    };
}
