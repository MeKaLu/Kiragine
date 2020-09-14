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
