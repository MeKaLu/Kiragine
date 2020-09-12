const std = @import("std");
usingnamespace @import("kira").log;

const kira_utils = @import("kira").utils;
const kira_glfw = @import("kira").glfw;
const kira_gl = @import("kira").gl;
const kira_window = @import("kira").window;

var window_running = false;
var targetfps: f64 = 1.0 / 60.0;

const vertex_source =
    \\#version 330 core
    \\layout(location = 0) in vec2 vPos;
    \\layout(location = 1) in vec3 vCol;
    \\out vec4 outCol;
    \\void main() {
    \\  gl_Position = vec4(vPos, 0.0, 1.0);
    \\  outCol = vec4(vCol, 1.0);
    \\}
;
const fragment_source =
    \\#version 330 core
    \\in vec4 outCol;
    \\void main() {
    \\  gl_FragColor = outCol; 
    \\}
;

fn closeCallback(handle: ?*c_void) void {
    window_running = false;
}

fn resizeCallback(handle: ?*c_void, w: i32, h: i32) void {
    kira_gl.viewport(0, 0, w, h);
}

pub fn main() !void {
    try kira_glfw.init();
    defer kira_glfw.deinit();
    kira_glfw.resizable(false);
    kira_glfw.initGLProfile();

    var window = kira_window.Info{};
    var frametime = kira_window.FrameTime{};
    var fps = kira_window.FpsDirect{};
    window.title = "Primtive Triangle Example";
    window.callbacks.close = closeCallback;
    window.callbacks.resize = resizeCallback;
    const sw = kira_glfw.getScreenWidth();
    const sh = kira_glfw.getScreenHeight();

    window.position.x = @divTrunc((sw - window.size.width), 2);
    window.position.y = @divTrunc((sh - window.size.height), 2);

    try window.create(false);
    defer window.destroy() catch unreachable;

    kira_glfw.makeContext(window.handle);
    kira_glfw.vsync(true);

    kira_gl.init();
    defer kira_gl.deinit();

    var program = try kira_gl.shaderProgramCreate(std.heap.page_allocator, vertex_source, fragment_source);
    defer kira_gl.shaderProgramDelete(program);

    const vertices = [_]f32{
        -0.5, -00.5, 0.0, 1.0, 0.0, 0.0,
        00.5, -00.5, 0.0, 0.0, 1.0, 0.0,
        00.0, 00.5,  0.0, 0.0, 0.0, 1.0,
    };

    var vbo: u32 = 0;
    var vao: u32 = 0;

    kira_gl.vertexArraysGen(1, @ptrCast([*]u32, &vao));
    kira_gl.buffersGen(1, @ptrCast([*]u32, &vbo));

    {
        kira_gl.vertexArrayBind(vao);
        kira_gl.bufferBind(kira_gl.BufferType.array, vbo);

        defer kira_gl.vertexArrayBind(0);
        defer kira_gl.bufferBind(kira_gl.BufferType.array, 0);

        kira_gl.bufferData(kira_gl.BufferType.array, @sizeOf(f32) * vertices.len, @ptrCast(?*const c_void, &vertices), kira_gl.DrawType.static);

        kira_gl.shaderProgramUse(program);
        defer kira_gl.shaderProgramUse(0);

        var offset: usize = @sizeOf(f32) * 3;

        kira_gl.shaderProgramSetVertexAttribArray(0, true);
        kira_gl.shaderProgramSetVertexAttribPointer(0, 3, f32, false, @sizeOf(f32) * 6, null);
        kira_gl.shaderProgramSetVertexAttribArray(1, true);
        kira_gl.shaderProgramSetVertexAttribPointer(1, 3, f32, false, @sizeOf(f32) * 6, @intToPtr(?*const c_void, offset));
    }

    window_running = true;
    while (window_running) {
        frametime.start();
        defer {
            kira_glfw.sync(window.handle);
            kira_glfw.processEvents();

            frametime.stop();
            frametime.sleep(targetfps);

            fps = fps.calculate(frametime);
            std.log.notice("FPS: {}", .{fps.fps}); 
        }

        kira_gl.clearColour(0.1, 0.1, 0.1, 1.0);
        kira_gl.clearBuffers(kira_gl.BufferBit.colour);

        kira_gl.shaderProgramUse(program);
        kira_gl.vertexArrayBind(vao);
        kira_gl.drawArrays(kira_gl.DrawMode.triangles, 0, 3);
    }
}
