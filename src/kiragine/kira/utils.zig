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
pub const Error = error{CheckFailed};
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
