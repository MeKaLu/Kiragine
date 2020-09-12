/// Error set
pub const Error = error{CheckFailed};
const std = @import("std");
usingnamespace @import("log.zig");

// TODO: Localized cross-platform(win32-posix) timer

/// If expresion is true return(CheckFailed) error
pub fn check(expression: bool, comptime msg: []const u8, va: anytype) Error!void {
    if (expression) {
        std.log.emerg(msg, va);
        return Error.CheckFailed;
    }
}