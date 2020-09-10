const std = @import("std");

const kira_utils = @import("kira").utils;
const kira_glfw = @import("kira").glfw;
const kira_gl = @import("kira").gl;
const kira_renderer = @import("kira").renderer;
const kira_window = @import("kira").window;

const math = @import("kira").math;

const Mat4x4f = math.mat4x4.Generic(f32);
const Vec3f = math.vec3.Generic(f32);
const Vertex = comptime kira_renderer.VertexGeneric(false, Vec3f);
const Batch = kira_renderer.BatchGeneric(1024, 6, 4, Vertex);

const Colour = kira_renderer.ColourGeneric(f32);

var window_running = false;
var targetfps: f64 = 1.0 / 60.0;

const vertex_shader =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\layout (location = 1) in vec4 aColor;
    \\out vec4 ourColor;
    \\uniform mat4 MVP;
    \\void main() {
    \\  gl_Position = MVP * vec4(aPos, 1.0);
    \\  ourColor = aColor;
    \\}
;

const fragment_shader =
    \\#version 330 core
    \\out vec4 final;
    \\in vec4 ourColor;
    \\void main() {
    \\  final = ourColor;
    \\}
;

fn closeCallback(handle: ?*c_void) void {
    window_running = false;
}

fn resizeCallback(handle: ?*c_void, w: i32, h: i32) void {
    kira_gl.viewport(0, 0, w, h);
}

fn shaderAttribs() void {
    const stride = @sizeOf(Vertex);
    kira_gl.shaderProgramSetVertexAttribArray(0, true);
    kira_gl.shaderProgramSetVertexAttribArray(1, true);

    kira_gl.shaderProgramSetVertexAttribPointer(0, 3, f32, false, stride, @intToPtr(?*const c_void, @byteOffsetOf(Vertex, "position")));
    kira_gl.shaderProgramSetVertexAttribPointer(1, 4, f32, false, stride, @intToPtr(?*const c_void, @byteOffsetOf(Vertex, "colour")));
}

fn submitFn(self: *Batch, vertex: [Batch.max_vertex_count]Vertex) kira_renderer.Error!void {
    try self.submitVertex(self.submission_counter, 0, vertex[0]);
    try self.submitVertex(self.submission_counter, 1, vertex[1]);
    try self.submitVertex(self.submission_counter, 2, vertex[2]);
    try self.submitVertex(self.submission_counter, 3, vertex[3]);

    if (self.submission_counter == 0) {
        try self.submitIndex(self.submission_counter, 0, 0);
        try self.submitIndex(self.submission_counter, 1, 1);
        try self.submitIndex(self.submission_counter, 2, 2);
        try self.submitIndex(self.submission_counter, 3, 2);
        try self.submitIndex(self.submission_counter, 4, 3);
        try self.submitIndex(self.submission_counter, 5, 0);
    } else {
        const back = self.index_list[self.submission_counter - 1];
        var i: u8 = 0;
        while (i < Batch.max_index_count) : (i += 1) {
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
        }
    }

    self.submission_counter += 1;
}

pub fn main() anyerror!void {
    try kira_utils.initTimer();
    defer kira_utils.deinitTimer();

    try kira_glfw.init();
    defer kira_glfw.deinit();
    kira_glfw.resizable(false);
    kira_glfw.initGLProfile();

    var window = kira_window.Info{};
    var frametime = kira_window.FrameTime{};
    var fps = kira_window.FpsDirect{};
    window.title = "Primitive Renderer Example";
    window.callbacks.close = closeCallback;
    window.callbacks.resize = resizeCallback;
    const sw = kira_glfw.getScreenWidth();
    const sh = kira_glfw.getScreenHeight();

    window.position.x = @divTrunc((sw - window.size.width), 2);
    window.position.y = @divTrunc((sh - window.size.height), 2);

    const ortho = Mat4x4f.ortho(0, @intToFloat(f32, window.size.width), @intToFloat(f32, window.size.height), 0, -1, 1);
    var cam = math.Camera2D{};
    cam.ortho = ortho;

    try window.create(false);
    defer window.destroy() catch unreachable;

    kira_glfw.makeContext(window.handle);
    kira_glfw.vsync(true);

    kira_gl.init();
    defer kira_gl.deinit();

    var shaderprogram = try kira_gl.shaderProgramCreate(std.heap.page_allocator, vertex_shader, fragment_shader);
    defer kira_gl.shaderProgramDelete(shaderprogram);

    var batch = Batch{};
    try batch.create(shaderprogram, shaderAttribs);
    defer batch.destroy();

    batch.submitfn = submitFn;

    const posx2 = 100;
    var posx: f32 = 400;
    const posy = 100;
    const w = 30;
    const h = 30;

    window_running = true;
    while (window_running) {
        frametime.start();

        batch.submission_counter = 0;

        posx += @floatCast(f32, targetfps) * 100;

        try batch.submitDrawable([Batch.max_vertex_count]Vertex{
            .{ .position = Vec3f{ .x = posx, .y = posy }, .colour = Colour.rgba(255, 255, 255, 255) },
            .{ .position = Vec3f{ .x = posx + w, .y = posy }, .colour = Colour.rgba(255, 255, 255, 255) },
            .{ .position = Vec3f{ .x = posx + w, .y = posy + h }, .colour = Colour.rgba(255, 255, 255, 255) },
            .{ .position = Vec3f{ .x = posx, .y = posy + h }, .colour = Colour.rgba(255, 255, 255, 255) },
        });

        try batch.submitDrawable([Batch.max_vertex_count]Vertex{
            .{ .position = Vec3f{ .x = posx2, .y = posy }, .colour = Colour.rgba(255, 255, 255, 255) },
            .{ .position = Vec3f{ .x = posx2 + w, .y = posy }, .colour = Colour.rgba(255, 255, 255, 255) },
            .{ .position = Vec3f{ .x = posx2 + w, .y = posy + h }, .colour = Colour.rgba(255, 255, 255, 255) },
            .{ .position = Vec3f{ .x = posx2, .y = posy + h }, .colour = Colour.rgba(255, 255, 255, 255) },
        });

        kira_gl.clearColour(0.1, 0.1, 0.1, 1.0);
        kira_gl.clearBuffers(kira_gl.BufferBit.colour);

        kira_gl.shaderProgramUse(shaderprogram);

        cam.attach();
        kira_gl.shaderProgramSetMat4x4f(kira_gl.shaderProgramGetUniformLocation(shaderprogram, "MVP"), @ptrCast([*]const f32, &cam.view.toArray()));

        try batch.draw(kira_gl.DrawMode.triangles);
        cam.detach();

        kira_glfw.sync(window.handle);
        kira_glfw.processEvents();

        frametime.stop();
        frametime.sleep(targetfps);

        fps = fps.calculate(frametime);
        kira_utils.printEndl(kira_utils.LogLevel.trace, "FPS: {}", .{fps.fps}) catch unreachable;
    }
}
