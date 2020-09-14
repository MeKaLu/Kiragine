const std = @import("std");
usingnamespace @import("log.zig");

// TODO: Localized cross-platform(win32-posix) timer

/// If expresion is true return(CheckFailed) error
pub fn check(expression: bool, comptime msg: []const u8, va: anytype) !void {
    if (expression) {
        std.log.emerg(msg, va);
        return error.CheckFailed;
    }
}