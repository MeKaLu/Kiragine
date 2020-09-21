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

/// Error set
pub const Error = error{ CheckFailed, Unknown, Duplicate, FailedToAdd };
const std = @import("std");
const gl = @import("gl.zig");
usingnamespace @import("log.zig");

// TODO: Localized cross-platform(win32-posix) timer

/// If expresion is true return(CheckFailed) error
pub fn check(expression: bool, comptime msg: []const u8, va: anytype) Error!void {
    if (expression) {
        std.log.emerg(msg, va);
        return Error.CheckFailed;
    }
}

/// Simple data collector
pub const DataPacker = struct {
    const Self = @This();
    pub const maximum_data = maximumdata;

    pub const Element = struct {
        start: usize = 0,
        end: usize = 0,
    };

    stack: usize = 0,
    allocatedsize: usize = 0,
    buffer: []u8 = undefined,
    allocator: *std.mem.Allocator = undefined,

    /// Initializes
    pub fn init(alloc: *std.mem.Allocator, reservedsize: usize) !Self {
        try check(reservedsize == 0, "kira/utils -> reservedsize cannot be zero!", .{});
        const self = Self{
            .allocator = alloc,
            .allocatedsize = reservedsize,
            .buffer = try alloc.alloc(u8, reservedsize),
            .stack = 0,
        };
        return self;
    }

    /// Deinitializes
    pub fn deinit(self: *Self) void {
        self.allocator.free(self.buffer);
        self.* = Self{};
    }

    /// Appends a data into buffer, deep copies it
    pub fn append(self: *Self, data: []const u8) !Element {
        if (self.stack < self.allocatedsize) {
            if (self.allocatedsize - self.stack < data.len) {
                try self.reserve(data.len);
            }
        }

        std.mem.copy(u8, self.buffer[self.stack..self.allocatedsize], data);
        self.stack += data.len;
        return Element{
            .start = self.stack - data.len,
            .end = self.stack,
        };
    }

    /// Reserves data
    pub fn reserve(self: *Self, size: usize) !void {
        try check(size == 0, "kira/utils -> size cannot be zero!", .{});
        self.buffer = try self.allocator.realloc(self.buffer, self.allocatedsize + size);
        self.allocatedsize = self.allocatedsize + size;
    }
};

pub fn UniqueList(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const typ = T;

        pub const Item = struct {
            data: typ = undefined,
            is_exists: bool = false,
        };

        allocator: *std.mem.Allocator = undefined,
        items: []Item = undefined,

        count: u64 = 0,
        total_capacity: u64 = 1,

        /// Allocates the memory
        pub fn init(alloc: *std.mem.Allocator, reserve: u64) !Self {
            var self = Self{
                .allocator = alloc,
                .items = undefined,
                .total_capacity = 1 + reserve,
                .count = 0,
            };
            self.items = try self.allocator.alloc(Item, self.total_capacity);
            self.clear();
            return self;
        }

        /// Frees the memory once
        pub fn deinit(self: *Self) void {
            self.allocator.free(self.items);
        }

        /// Clears the list
        pub fn clear(self: *Self) void {
            var i: u64 = 0;
            while (i < self.total_capacity) : (i += 1) {
                self.items[i].is_exists = false;
                self.items[i].data = undefined;
            }
            self.count = 0;
        }

        /// Increases the capacity
        pub fn increaseCapacity(self: *Self, reserve: u64) !void {
            var buf = self.items;
            self.items = try self.allocator.alloc(Item, self.total_capacity + reserve);
            var i: u64 = 0;
            while (i < self.total_capacity) : (i += 1) {
                self.items[i] = buf[i];
            }
            self.allocator.free(buf);

            self.total_capacity += reserve;
            while (i < self.total_capacity) : (i += 1) {
                self.items[i].is_exists = false;
                self.items[i].data = undefined;
            }
        }

        /// It cannot decrease a used space,
        /// call it after calling the 'clear' function
        pub fn decreaseCapacity(self: *Self, reserve: u64) !void {
            if (self.total_capacity - reserve <= self.count) return;
            var buf = self.items;
            self.items = try self.allocator.alloc(Item, self.total_capacity - reserve);
            var i: u64 = self.total_capacity;
            while (i >= 0) : (i -= 1) {
                self.items[i] = buf[i];
            }
            self.allocator.free(buf);
            self.total_capacity -= reserve;
        }

        /// Insert an item, it fails if the item was a duplicate
        pub fn insert(self: *Self, item: typ, autoincrease: bool) !void {
            var i: u64 = 0;
            while (i < self.total_capacity) : (i += 1) {
                if (self.items[i].is_exists and self.items[i].data == item) {
                    return Error.Duplicate;
                } else if (!self.items[i].is_exists) {
                    self.items[i].data = item;
                    self.items[i].is_exists = true;
                    self.count += 1;
                    return;
                }
            }
            if (autoincrease) {
                try self.increaseCapacity(1);
                return self.insert(item, false);
            }

            return Error.FailedToAdd;
        }

        /// Remove an item
        pub fn remove(self: *Self, item: typ) Error!void {
            var i: u64 = 0;
            while (i < self.total_capacity) : (i += 1) {
                if (self.items[i].is_exists and self.items[i].data == item) {
                    self.items[i].is_exists = false;
                    self.items[i].data = undefined;
                    return;
                }
            }
            return Error.Unknown;
        }

        /// Get an item index
        pub fn getIndex(self: Self, item: typ) Error!u64 {
            var i: u64 = 0;
            while (i < self.total_capacity) : (i += 1) {
                if (self.items[i].is_exists and self.items[i].data == item) {
                    return i;
                }
            }
            return Error.Unknown;
        }

        /// Does the data exists?
        pub fn isExists(self: Self, item: typ) bool {
            var i: u64 = 0;
            while (i < self.total_capacity) : (i += 1) {
                if (self.items[i].is_exists and self.items[i].data == item) {
                    return true;
                }
            }
            return false;
        }

        /// Turn the existing data into array
        pub fn convertToArray(self: Self, comptime tp: type, comptime len: u64) [len]tp {
            var result: [len]typ = undefined;
            var i: u64 = 0;
            while (i < self.total_capacity) : (i += 1) {
                if (self.items[i].is_exists) {
                    result[i] = self.items[i].data;
                }
            }
            return result;
        }
    };
}
