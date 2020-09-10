// -----------------------------------------
// |           Kiragine 1.0.0              |
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
const Builder = @import("std").build.Builder;
const Build = @import("std").build;
const Builtin = @import("std").builtin;
const Zig = @import("std").zig;

const flags = [_][]const u8{ "-O2", "-std=c99" };

fn setup(exe: *Build.LibExeObjStep, target: Zig.CrossTarget) void {
    const target_os = exe.target.toTarget().os.tag;
    switch (target_os) {
        .windows => {
            exe.setTarget(target);

            exe.linkSystemLibrary("gdi32");
            exe.linkSystemLibrary("opengl32");

            exe.subsystem = Builtin.SubSystem.Console;
        },
        .linux => {
            exe.setTarget(target);
            exe.linkSystemLibrary("X11");
        },
        else => {},
    }
}

fn addSourceFiles(exe: *Build.LibExeObjStep, target: Zig.CrossTarget, comptime enginepath: []const u8) void {
    exe.linkSystemLibrary("c");

    const target_os = exe.target.toTarget().os.tag;
    switch (target_os) {
        .windows => {
            exe.setTarget(target);

            exe.subsystem = Builtin.SubSystem.Console;

            exe.linkSystemLibrary("gdi32");
            exe.linkSystemLibrary("opengl32");

            exe.defineCMacro("_GLFW_WIN32");

            exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/wgl_context.c", &flags);

            exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/win32_init.c", &flags);
            exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/win32_joystick.c", &flags);
            exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/win32_monitor.c", &flags);
            exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/win32_thread.c", &flags);
            exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/win32_time.c", &flags);
            exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/win32_window.c", &flags);
        },
        .linux => {
            exe.setTarget(target);
            exe.linkSystemLibrary("X11");

            exe.defineCMacro("_GLFW_X11");

            exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/glx_context.c", &flags);

            exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/posix_thread.c", &flags);
            exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/posix_time.c", &flags);

            //exe.addCSourceFile("include/glfw-3.3.2/src/wl_init.c", &flags);
            //exe.addCSourceFile("include/glfw-3.3.2/src/wl_window.c", &flags);
            //exe.addCSourceFile("include/glfw-3.3.2/src/wl_monitor.c", &flags);

            exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/x11_init.c", &flags);
            exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/x11_window.c", &flags);
            exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/x11_monitor.c", &flags);

            exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/xkb_unicode.c", &flags);
            exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/linux_joystick.c", &flags);
        },
        else => {},
    }

    exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/init.c", &flags);
    exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/context.c", &flags);
    exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/input.c", &flags);
    exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/monitor.c", &flags);
    exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/window.c", &flags);
    exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/vulkan.c", &flags);

    exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/osmesa_context.c", &flags);
    exe.addCSourceFile(enginepath ++ "include/glfw-3.3.2/src/egl_context.c", &flags);

    //exe.addCSourceFile("include/glfw-3.3.2/src/null_init.c", &flags);
    //exe.addCSourceFile("include/glfw-3.3.2/src/null_joystick.c", &flags);
    //exe.addCSourceFile("include/glfw-3.3.2/src/null_monitor.c", &flags);
    //exe.addCSourceFile("include/glfw-3.3.2/src/null_window.c", &flags);

    exe.addCSourceFile(enginepath ++ "include/onefile/GLAD/gl.c", &flags);
    exe.addCSourceFile(enginepath ++ "include/onefile/stb/image.c", &flags);
}

pub fn buildExe(b: *Builder, target: Zig.CrossTarget, mode: Builtin.Mode, path: []const u8, name: []const u8, lib: *Build.LibExeObjStep, comptime enginepath: []const u8) *Build.LibExeObjStep {
    const exe = b.addExecutable(name, path);
    exe.setOutputDir("build");
    exe.linkSystemLibrary("c");

    setup(exe, target);

    exe.addIncludeDir(enginepath ++ "include/glfw-3.3.2/include/");
    exe.addIncludeDir(enginepath ++ "include/onefile/");

    exe.addLibPath("build/");
    exe.linkSystemLibrary("kiragine");

    exe.addPackagePath("kiragine", enginepath ++ "src/kiragine/kiragine.zig");

    exe.setBuildMode(mode);
    exe.install();

    return exe;
}

pub fn buildExePrimitive(b: *Builder, target: Zig.CrossTarget, mode: Builtin.Mode, path: []const u8, name: []const u8, lib: *Build.LibExeObjStep, comptime enginepath: []const u8) *Build.LibExeObjStep {
    const exe = b.addExecutable(name, path);
    exe.setOutputDir("build");
    exe.linkSystemLibrary("c");

    setup(exe, target);

    exe.addIncludeDir(enginepath ++ "include/glfw-3.3.2/include/");
    exe.addIncludeDir(enginepath ++ "include/onefile/");

    exe.addLibPath("build/");
    exe.linkSystemLibrary("kiragine");

    exe.addPackagePath("kira", enginepath ++ "src/kiragine/kira/kira.zig");

    exe.setBuildMode(mode);
    exe.install();

    return exe;
}

pub fn buildEngineStatic(b: *Builder, target: Zig.CrossTarget, mode: Builtin.Mode, comptime enginepath: []const u8) *Build.LibExeObjStep {
    // WARN: Building a shared library does not work on windows
    var exe: *Build.LibExeObjStep = undefined;

    exe = b.addStaticLibrary("kiragine", enginepath ++ "src/kiragine/kiragine.zig");
    exe.setOutputDir("build");

    exe.addIncludeDir(enginepath ++ "include/glfw-3.3.2/include/");
    exe.addIncludeDir(enginepath ++ "include/onefile/");
    addSourceFiles(exe, target, enginepath);

    exe.setBuildMode(mode);
    exe.install();

    return exe;
}

pub fn buildEngine(b: *Builder, target: Zig.CrossTarget, mode: Builtin.Mode, comptime enginepath: []const u8) *Build.LibExeObjStep {
    var exe: *Build.LibExeObjStep = undefined;

    const shared = comptime if (std.Target.current.os.tag == .linux) true else false;
    if (!shared) {
        return buildEngineStatic(b, target, mode, enginepath);
    }

    // WARN: Building a shared library does not work on windows
    exe = b.addSharedLibrary("kiragine", enginepath ++ "src/kiragine/kiragine.zig", Build.Version{ .major = 1, .minor = 0, .patch = 0 });
    exe.setOutputDir("build");

    exe.addIncludeDir(enginepath ++ "include/glfw-3.3.2/include/");
    exe.addIncludeDir(enginepath ++ "include/onefile/");
    addSourceFiles(exe, target, enginepath);

    exe.setBuildMode(mode);
    exe.install();

    return exe;
}
