// -----------------------------------------
// |           Kiragine 1.0.2              |
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

/// Static colour defines
const colours: [6][]const u8 = comptime [6][]const u8{
    "\x1b[94m", "\x1b[36m",
    "\x1b[32m", "\x1b[33m",
    "\x1b[31m", "\x1b[35m",
};

///  level names
const level_names: [6][]const u8 = comptime [6][]const u8{
    "KIRA:TRACE", "KIRA:DEBUG",
    "KIRA:INFO",  "KIRA:WARNING",
    "KIRA:ERROR", "KIRA:PANIC",
};

var pfile: ?std.fs.File = null;
var timer: std.time.Timer = undefined;

/// Log levels
pub const LogLevel = enum {
    trace = 0,
    debug,
    info,
    warn,
    err,
    panic,
};

/// Error set
pub const Error = error{CheckFailed};

// TODO: Localized cross-platform(win32-posix) timer

/// Initiatizes the timer
pub fn initTimer() !void {
    timer = try std.time.Timer.start();
}

/// Deinitializes the timer
pub fn deinitTimer() void {
    timer.reset();
}

/// Get elapsed time from the timer
pub fn getElapsedTime() u64 {
    return timer.read();
}

/// If expresion is true return(CheckFailed) error
pub fn check(expression: bool, comptime msg: []const u8, va: anytype) !void {
    if (expression) {
        try printEndl(LogLevel.panic, msg, va);
        return Error.CheckFailed;
    }
}

/// Creates the log file
pub fn logCreateFile(fileName: []const u8) !bool {
    if (pfile == null) {
        pfile = try std.fs.cwd().createFile(fileName, .{});
        return true;
    }
    return false;
}

/// Opens the log file
pub fn logOpenFile(fileName: []const u8) !bool {
    if (pfile == null) {
        pfile = try std.fs.cwd().openFile(fileName, .{ .write = true, .read = false });
        return true;
    }
    return false;
}

/// Closes the log file
pub fn logCloseFile() bool {
    if (pfile) |file| {
        file.close();
        return true;
    }
    return false;
}

/// Logs the given output and prints it with endl
pub fn printEndl(level: LogLevel, comptime fmt: []const u8, va: anytype) !void {
    const level_name = level_names[@enumToInt(level)];
    const counter = timer.read() / 1000000000;

    if (pfile) |file| {
        var buffer: [512]u8 = undefined;
        try file.writeAll(try std.fmt.bufPrint(&buffer, "{}:{} -> ", .{ counter, level_name }));
        try file.writeAll(try std.fmt.bufPrint(&buffer, fmt, va));
        try file.writeAll(try std.fmt.bufPrint(&buffer, "\n", .{}));
    }

    if (log_coloured) {
        const level_colour = colours[@enumToInt(level)];
        std.debug.print("{}:{}{}\x1b[37m -> ", .{ counter, level_colour, level_name });
        std.debug.print(fmt, va);
        std.debug.print("\x1b[0m\n", .{});
    } else {
        std.debug.print("{}:{} -> ", .{ counter, level_name });
        std.debug.print(fmt, va);
        std.debug.print("\n", .{});
    }
}

/// Logs the given output and prints it without endl
pub fn printNoEndl(level: LogLevel, comptime fmt: []const u8, va: anytype) !void {
    const level_name = level_names[@enumToInt(level)];
    const counter = timer.read() / 1000000000;

    if (pfile) |file| {
        var buffer: [512]u8 = undefined;
        try file.writeAll(try std.fmt.bufPrint(&buffer, "{}:{} -> ", .{ counter, level_name }));
        try file.writeAll(try std.fmt.bufPrint(&buffer, fmt, va));
    }

    if (log_coloured) {
        const level_colour = colours[@enumToInt(level)];
        std.debug.print("{}:{}{}\x1b[37m -> ", .{ counter, level_colour, level_name });
        std.debug.print(fmt, va);
        std.debug.print("\x1b[0m", .{});
    } else {
        std.debug.print("{}:{} -> ", .{ counter, level_name });
        std.debug.print(fmt, va);
    }
}
