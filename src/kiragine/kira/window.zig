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

const c = @import("c.zig");
const getElapsedTime = @import("glfw.zig").getElapsedTime;
const utils = @import("utils.zig");

const time = @import("std").time;
const print = @import("std").debug.print;

pub const FrameTime = struct {
    update: f64 = 0,
    draw: f64 = 0,
    delta: f64 = 0,
    last: f64 = 0,
    current: f64 = 0,

    /// Start updating frametime
    pub fn start(fr: *FrameTime) void {
        fr.current = getElapsedTime();
        fr.update = fr.current - fr.last;
        fr.last = fr.current;
    }
    /// Stop updating frametime
    pub fn stop(fr: *FrameTime) void {
        fr.current = getElapsedTime();
        fr.draw = fr.current - fr.last;
        fr.last = fr.current;

        fr.delta = fr.update + fr.draw;
    }
    /// Sleep for the sake of cpu
    pub fn sleep(fr: *FrameTime, targetfps: f64) void {
        if (fr.delta < targetfps) {
            const ms = (targetfps - fr.delta) * 1000;
            const sleep_time = ms * 1000000;
            time.sleep(@floatToInt(u64, sleep_time));

            fr.current = getElapsedTime();
            fr.delta += fr.current - fr.last;
            fr.last = fr.current;
        }
    }
};

pub const FpsDirect = struct {
    counter: u32 = 0,
    fps: u32 = 0,
    last: f64 = 0,

    /// Calculates the fps
    pub fn calculate(fp: FpsDirect, fr: FrameTime) FpsDirect {
        var fps = fp;
        const fuck = fr.current - fps.last;
        fps.counter += 1;
        if (fuck >= 1.0) {
            fps.fps = fps.counter;
            fps.counter = 0;
            fps.last = fr.current;
        }
        return fps;
    }
};

pub const Info = struct {
    handle: ?*c_void = null,
    title: []const u8 = "<Insert Title>",

    size: Size = Size{},
    minsize: Size = Size{},
    maxsize: Size = Size{},
    position: Position = Position{},
    callbacks: Callbacks = Callbacks{},

    pub const Size = struct {
        width: i32 = 1024,
        height: i32 = 768,
    };
    pub const Position = struct {
        x: i32 = 0,
        y: i32 = 0,
    };
    pub const UpdateProperty = enum {
        size, sizelimits, title, position, all
    };
    pub const Callbacks = struct {
        close: ?fn (handle: ?*c_void) void = null,
        resize: ?fn (handle: ?*c_void, w: i32, h: i32) void = null,
        mousepos: ?fn (handle: ?*c_void, x: f64, y: f64) void = null,
        mouseinp: ?fn (handle: ?*c_void, key: i32, ac: i32, mods: i32) void = null,
        keyinp: ?fn (handle: ?*c_void, key: i32, sc: i32, ac: i32, mods: i32) void = null,
        textinp: ?fn (handle: ?*c_void, codepoint: u32) void = null,
    };

    /// Create the window
    pub fn create(win: *Info, fullscreen: bool) !void {
        try utils.check(win.handle != null, "kira/window -> handle must be null", .{});
        win.handle = @ptrCast(?*c_void, c.glfwCreateWindow(win.size.width, win.size.height, @ptrCast([*c]const u8, win.title), if (fullscreen) c.glfwGetPrimaryMonitor() else null, null));
        try utils.check(win.handle == null, "kira/window -> glfw could not create window handle!", .{});

        if (win.callbacks.close != null) {
            _ = c.glfwSetWindowCloseCallback(@ptrCast(?*c.struct_GLFWwindow, win.handle), @ptrCast(c.GLFWwindowclosefun, win.callbacks.close));
        }
        if (win.callbacks.resize != null) {
            _ = c.glfwSetWindowSizeCallback(@ptrCast(?*c.struct_GLFWwindow, win.handle), @ptrCast(c.GLFWwindowsizefun, win.callbacks.resize));
        }
        if (win.callbacks.mousepos != null) {
            _ = c.glfwSetCursorPosCallback(@ptrCast(?*c.struct_GLFWwindow, win.handle), @ptrCast(c.GLFWcursorposfun, win.callbacks.mousepos));
        }
        if (win.callbacks.mouseinp != null) {
            _ = c.glfwSetMouseButtonCallback(@ptrCast(?*c.struct_GLFWwindow, win.handle), @ptrCast(c.GLFWmousebuttonfun, win.callbacks.mouseinp));
        }
        if (win.callbacks.keyinp != null) {
            _ = c.glfwSetKeyCallback(@ptrCast(?*c.struct_GLFWwindow, win.handle), @ptrCast(c.GLFWkeyfun, win.callbacks.keyinp));
        }
        if (win.callbacks.textinp != null) {
            _ = c.glfwSetCharCallback(@ptrCast(?*c.struct_GLFWwindow, win.handle), @ptrCast(c.GLFWcharfun, win.callbacks.textinp));
        }

        win.update(UpdateProperty.all);
    }
    /// Destroys the window
    pub fn destroy(win: *Info) !void {
        try utils.check(win.handle == null, "kira/window -> handle must be valid", .{});
        c.glfwDestroyWindow(@ptrCast(?*c.struct_GLFWwindow, win.handle));
        win.handle = null;
    }
    /// Updates the properties
    pub fn update(win: *Info, p: UpdateProperty) void {
        switch (p) {
            UpdateProperty.size => {
                c.glfwSetWindowSize(@ptrCast(?*c.struct_GLFWwindow, win.handle), win.size.width, win.size.height);
            },
            UpdateProperty.sizelimits => {
                c.glfwSetWindowSizeLimits(@ptrCast(?*c.struct_GLFWwindow, win.handle), win.minsize.width, win.minsize.height, win.maxsize.width, win.maxsize.height);
            },
            UpdateProperty.title => {
                c.glfwSetWindowTitle(@ptrCast(?*c.struct_GLFWwindow, win.handle), @ptrCast([*c]const u8, win.title));
            },
            UpdateProperty.position => {
                c.glfwSetWindowPos(@ptrCast(?*c.struct_GLFWwindow, win.handle), win.position.x, win.position.y);
            },
            UpdateProperty.all => {
                c.glfwSetWindowSize(@ptrCast(?*c.struct_GLFWwindow, win.handle), win.size.width, win.size.height);
                c.glfwSetWindowSizeLimits(@ptrCast(?*c.struct_GLFWwindow, win.handle), win.minsize.width, win.minsize.height, win.maxsize.width, win.maxsize.height);
                c.glfwSetWindowTitle(@ptrCast(?*c.struct_GLFWwindow, win.handle), @ptrCast([*c]const u8, win.title));
                c.glfwSetWindowPos(@ptrCast(?*c.struct_GLFWwindow, win.handle), win.position.x, win.position.y);
            },
        }
    }
};
