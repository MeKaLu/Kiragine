const std = @import("std");
usingnamespace @import("kira").log;

const kira_utils = @import("kira").utils;
const kira_glfw = @import("kira").glfw;
const kira_gl = @import("kira").gl;
const kira_window = @import("kira").window;
const kira_input = @import("kira").input;

var window_running = false;
var targetfps: f64 = 1.0 / 60.0;

var input = kira_input.Info{};

fn closeCallback(handle: ?*c_void) void {
    window_running = false;
}

fn resizeCallback(handle: ?*c_void, w: i32, h: i32) void {
    kira_gl.viewport(0, 0, w, h);
}

fn keyboardCallback(handle: ?*c_void, key: i32, sc: i32, ac: i32, mods: i32) void {
    input.handleKeyboard(key, ac) catch unreachable;
}

pub fn main() !void {
    try kira_glfw.init();
    defer kira_glfw.deinit();
    kira_glfw.resizable(false);
    kira_glfw.initGLProfile();

    var window = kira_window.Info{};
    var frametime = kira_window.FrameTime{};
    var fps = kira_window.FpsDirect{};
    window.title = "Primitive window creation and I/O Example";
    window.callbacks.close = closeCallback;
    window.callbacks.resize = resizeCallback;
    window.callbacks.keyinp = keyboardCallback;
    const sw = kira_glfw.getScreenWidth();
    const sh = kira_glfw.getScreenHeight();

    window.position.x = @divTrunc((sw - window.size.width), 2);
    window.position.y = @divTrunc((sh - window.size.height), 2);

    try window.create(false);
    defer window.destroy() catch unreachable;

    input.bindKey('A') catch |err| {
        if (err == error.NoEmptyBinding) {
            input.clearAllBindings();
            try input.bindKey('A');
        } else return err;
    };

    const keyA = try input.keyStatePtr('A');

    kira_glfw.makeContext(window.handle);
    kira_glfw.vsync(true);

    kira_gl.init();
    defer kira_gl.deinit();

    window_running = true;
    while (window_running) {
        frametime.start();

        std.log.debug("Key A: {}", .{keyA});

        input.handle();

        kira_gl.clearColour(0.1, 0.1, 0.1, 1.0);
        kira_gl.clearBuffers(kira_gl.BufferBit.colour);

        defer {
            kira_glfw.sync(window.handle);
            kira_glfw.processEvents();

            frametime.stop();
            frametime.sleep(targetfps);

            fps = fps.calculate(frametime);
            std.log.notice("FPS: {}", .{fps.fps}); 
        }
    }
}
