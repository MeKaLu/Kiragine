// -----------------------------------------
// |           Kiragine 1.1.1              |
// -----------------------------------------
// Copyright © 2020-1020 Mehmet Kaan Uluç <kaanuluc@protonmail.com>
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

const c = @import("c.zig");
const std = @import("std");
usingnamespace @import("log.zig");

/// Error set
pub const Error = error{GLFWFailedToInitialize};

fn errorCallback(err: i32, desc: [*c]const u8) callconv(.C) void {
    std.log.emerg("GLFW -> {}:{*}", .{ err, desc });
}

/// Initializes glfw
pub fn init() Error!void {
    _ = c.glfwSetErrorCallback(errorCallback);
    if (c.glfwInit() == 0) return Error.GLFWFailedToInitialize;
}

/// Deinitializes glfw
pub fn deinit() void {
    c.glfwTerminate();
}

/// Sets the next created window resize status
pub fn resizable(enable: bool) void {
    c.glfwWindowHint(c.GLFW_RESIZABLE, if (enable) 1 else 0);
}

/// Returns the elapsed time
pub fn getElapsedTime() f64 {
    return c.glfwGetTime();
}

/// Initialize glfw gl profile
pub fn initGLProfile() void {
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
}

/// Make glfw window context
pub fn makeContext(handle: ?*c_void) void {
    c.glfwMakeContextCurrent(@ptrCast(?*c.struct_GLFWwindow, handle));
}

/// Wait while window closes(returns true if should run)
pub fn shouldWindowRun(handle: ?*c_void) bool {
    return if (c.glfwWindowShouldClose(@ptrCast(?*c.struct_GLFWwindow, handle)) == 0) true else false;
}

/// Returns width of the primary monitor
pub fn getScreenWidth() i32 {
    var monitor = c.glfwGetPrimaryMonitor();
    const mode = c.glfwGetVideoMode(monitor);
    return mode.*.width;
}

/// Returns height of the primary monitor
pub fn getScreenHeight() i32 {
    var monitor = c.glfwGetPrimaryMonitor();
    const mode = c.glfwGetVideoMode(monitor);
    return mode.*.height;
}

/// Returns refresh rate of the primary monitor
pub fn getScreenRefreshRate() i32 {
    var monitor = c.glfwGetPrimaryMonitor();
    const mode = c.glfwGetVideoMode(monitor);
    return mode.*.refreshRate;
}

/// Polls the events
pub fn processEvents() void {
    c.glfwPollEvents();
}

/// Swap buffers/sync the window with opengl
pub fn sync(handle: ?*c_void) void {
    c.glfwSwapBuffers(@ptrCast(?*c.struct_GLFWwindow, handle));
}

/// Enable/Disable vsync
pub fn vsync(enable: bool) void {
    c.glfwSwapInterval(if (enable) 1 else 0);
}
