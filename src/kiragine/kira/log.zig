// -----------------------------------------
// |           Kiragine 1.1.0              |
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

const log_coloured = comptime if (std.Target.current.os.tag == .linux) true else false;

// Source: https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
/// Static colour defines
const colours = comptime [_][]const u8{
    "\x1b[1;31m", // emerg
    "\x1b[1;91m", // alert
    "\x1b[1;35m", // crit
    "\x1b[95m", // err
    "\x1b[93m", // warn
    "\x1b[32m", // notice
    "\x1b[94m", // info
    "\x1b[36m", // debug
};
const colour_reset = "\x1b[0m";
const colour_gray = "\x1b[90m";
const colour_white = "\x1b[97m";

var counter: u64 = 0;
const maxcounter = std.math.maxInt(u64);

// Define root.log to override the std implementation
pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const held = std.debug.getStderrMutex().acquire();
    defer held.release();
    const stderr = std.io.getStdErr().writer();

    if (!log_coloured) {
        const scope_prefix = "(" ++ @tagName(scope) ++ "):";
        const prefix = "[" ++ @tagName(level) ++ "] " ++ scope_prefix;

        nosuspend stderr.print("{}:", .{counter}) catch return;
        nosuspend stderr.print(prefix ++ format ++ "\n", args) catch return;
    } else {
        const scope_prefix = "(" ++ @tagName(scope) ++ "):";
        const prefix = "[" ++ colours[@enumToInt(level)] ++ @tagName(level) ++ colour_reset ++ "] " ++ colour_gray ++ scope_prefix ++ colour_reset;

        nosuspend stderr.print("{}:", .{counter}) catch return;
        nosuspend stderr.print(prefix ++ colour_white ++ format ++ "\n" ++ colour_reset, args) catch return;
    }
    if (counter >= maxcounter) logReset();
    counter += 1;
}

/// Resets the log counter
pub fn logReset() void {
    counter = 0;
}
