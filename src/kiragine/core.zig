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

// TODO: Draw circles
// TODO: Text rendering
// TODO: Simple particle system
// TODO: Simple layering system
// TODO: Custom shaders with custom batch systems
// (abstract it and make it work with the current draw methods. API breaking change!)

const std = @import("std");

const getElapsedTime = @import("kira/glfw.zig").getElapsedTime;
const glfw = @import("kira/glfw.zig");
const renderer = @import("kira/renderer.zig");
const gl = @import("kira/gl.zig");
const c = @import("kira/c.zig");
const input = @import("kira/input.zig");
const window = @import("kira/window.zig");
const utils = @import("kira/utils.zig");

const cam = @import("kira/math/camera.zig");
const mat4x4 = @import("kira/math/mat4x4.zig");
const math = @import("kira/math/common.zig");
const vec2 = @import("kira/math/vec2.zig");
const vec3 = @import("kira/math/vec3.zig");

const Vertex2DNoTexture = comptime renderer.VertexGeneric(false, Vec2f);
const Vertex2DTexture = comptime renderer.VertexGeneric(true, Vec2f);
const Batch2DQuadNoTexture = comptime renderer.BatchGeneric(1024 * 8, 6, 4, Vertex2DNoTexture);
const Batch2DQuadTexture = comptime renderer.BatchGeneric(1024 * 8, 6, 4, Vertex2DTexture);

pub const Mat4x4f = mat4x4.Generic(f32);
pub const Vec2f = vec2.Generic(f32);
pub const Vec3f = vec3.Generic(f32);

pub const Window = window.Info;
pub const WindowError = window.Error;

pub const Input = input.Info;
pub const InputError = input.Error;

pub const Camera2D = cam.Camera2D;
pub const Colour = renderer.ColourGeneric(f32);
pub const UColour = renderer.ColourGeneric(u8);

/// Error set
pub const Error = error{ EngineIsNotInitialized, EngineIsInitialized, InvalidBatch, FailedToLoadTexture, FailedToDraw, InvalidRendererTag };

pub const Rectangle = struct {
    x: f32 = 0,
    y: f32 = 0,
    width: f32 = 0,
    height: f32 = 0,
};

pub const Renderer2DBatchTag = enum {
    none,
    pixels,
    lines,
    /// Triangle & rectangle draw can also be used in non-textured quad batch
    triangles,
    /// Triangle & rectangle draw can also be used in non-textured quad batch
    quad,
};

pub const Texture = struct {
    id: u32 = 0,
    width: i32 = 0,
    height: i32 = 0,

    fn loadSetup(self: *Texture) void {
        gl.texturesGen(1, @ptrCast([*]u32, &self.id));
        gl.textureBind(gl.TextureType.t2D, self.id);

        gl.textureTexParameteri(gl.TextureType.t2D, gl.TextureParamaterType.min_filter, gl.TextureParamater.filter_nearest);
        gl.textureTexParameteri(gl.TextureType.t2D, gl.TextureParamaterType.mag_filter, gl.TextureParamater.filter_nearest);

        gl.textureTexParameteri(gl.TextureType.t2D, gl.TextureParamaterType.wrap_s, gl.TextureParamater.wrap_repeat);
        gl.textureTexParameteri(gl.TextureType.t2D, gl.TextureParamaterType.wrap_t, gl.TextureParamater.wrap_repeat);
    }

    /// Creates a texture from png file
    pub fn createFromPNG(path: []const u8) anyerror!Texture {
        var result = Texture{};
        result.loadSetup();
        defer gl.textureBind(gl.TextureType.t2D, 0);

        var nrchannels: i32 = 0;

        c.stbi_set_flip_vertically_on_load(0);
        var data: ?*u8 = c.stbi_load(@ptrCast([*c]const u8, path), &result.width, &result.height, &nrchannels, 4);
        defer c.stbi_image_free(data);

        if (data == null) return Error.FailedToLoadTexture;

        gl.textureTexImage2D(gl.TextureType.t2D, 0, gl.TextureFormat.rgba8, result.width, result.height, 0, gl.TextureFormat.rgba, u8, data);

        return result;
    }

    /// Creates a texture from png memory
    pub fn createFromPNGMemory(mem: []const u8) anyerror!Texture {
        var result = Texture{};
        result.loadSetup();
        defer gl.textureBind(gl.TextureType.t2D, 0);

        var nrchannels: i32 = 0;

        c.stbi_set_flip_vertically_on_load(0);
        var data: ?*u8 = c.stbi_load_from_memory(@ptrCast([*c]const u8, mem), @intCast(i32, mem.len), &result.width, &result.height, &nrchannels, 4);
        defer c.stbi_image_free(data);

        if (data == null) return Error.FailedToLoadTexture;

        gl.textureTexImage2D(gl.TextureType.t2D, 0, gl.TextureFormat.rgba8, result.width, result.height, 0, gl.TextureFormat.rgba, u8, data);

        return result;
    }

    /// Creates a texture from given colour
    pub fn createFromColour(colour: [*]UColour, w: i32, h: i32) Texture {
        var result = Texture{ .width = w, .height = h };
        result.loadSetup();
        defer gl.textureBind(gl.TextureType.t2D, 0);

        gl.textureTexImage2D(gl.TextureType.t2D, 0, gl.TextureFormat.rgba8, result.width, result.height, 0, gl.TextureFormat.rgba, u8, @ptrCast(?*c_void, colour));
        return result;
    }

    /// Destroys the texture
    pub fn destroy(self: *Texture) void {
        gl.texturesDelete(1, @ptrCast([*]const u32, &self.id));
        self.id = 0;
    }
};

/// Helper type
const Renderer2D = struct {
    cam: Camera2D = Camera2D{},
    quadbatch_notexture: Batch2DQuadNoTexture = Batch2DQuadNoTexture{},
    quadbatch_texture: Batch2DQuadTexture = Batch2DQuadTexture{},
    notextureshader: u32 = 0,
    textureshader: u32 = 0,
    current_texture: Texture = Texture{},
    tag: Renderer2DBatchTag = Renderer2DBatchTag.none,
    textured: bool = false,
};

/// Helper type
const ModelMatrix = struct {
    model: Mat4x4f = Mat4x4f.identity(),
    trans: Mat4x4f = Mat4x4f.identity(),
    rot: Mat4x4f = Mat4x4f.identity(),
    sc: Mat4x4f = Mat4x4f.identity(),

    pub fn update(self: *ModelMatrix) void {
        self.model = Mat4x4f.mul(self.sc, Mat4x4f.mul(self.trans, self.rot));
    }

    pub fn translate(self: *ModelMatrix, x: f32, y: f32, z: f32) void {
        self.trans = Mat4x4f.translate(x, y, z);
        self.update();
    }

    pub fn rotate(self: *ModelMatrix, x: f32, y: f32, z: f32, angle: f32) void {
        self.rot = Mat4x4f.rotate(x, y, z, angle);
        self.update();
    }

    pub fn scale(self: *ModelMatrix, x: f32, y: f32, z: f32) void {
        self.sc = Mat4x4f.scale(x, y, z);
        self.update();
    }
};

const pnotexture_vertex_shader =
    \\#version 330 core
    \\layout (location = 0) in vec2 aPos;
    \\layout (location = 1) in vec4 aColour;
    \\
    \\out vec4 ourColour;
    \\uniform mat4 MVP;
    \\
    \\void main() {
    \\  gl_Position = MVP * vec4(aPos.xy, 0.0, 1.0);
    \\  ourColour = aColour;
    \\}
;

const pnotexture_fragment_shader =
    \\#version 330 core
    \\
    \\out vec4 final;
    \\in vec4 ourColour;
    \\
    \\void main() {
    \\  final = ourColour;
    \\}
;

const ptexture_vertex_shader =
    \\#version 330 core
    \\layout (location = 0) in vec2 aPos;
    \\layout (location = 1) in vec2 aTexCoord;
    \\layout (location = 2) in vec4 aColour;
    \\
    \\out vec2 ourTexCoord;
    \\out vec4 ourColour;
    \\uniform mat4 MVP;
    \\
    \\void main() {
    \\  gl_Position = MVP * vec4(aPos.xy, 0.0, 1.0);
    \\  ourTexCoord = aTexCoord;
    \\  ourColour = aColour;
    \\}
;

const ptexture_fragment_shader =
    \\#version 330 core
    \\
    \\out vec4 final;
    \\in vec2 ourTexCoord;
    \\in vec4 ourColour;
    \\uniform sampler2D uTexture;
    \\
    \\void main() {
    \\  vec4 texelColour = texture(uTexture, ourTexCoord);
    \\  final = ourColour * texelColour;
    \\}
;

fn pnoTextureShaderAttribs() void {
    const stride = @sizeOf(Vertex2DNoTexture);
    gl.shaderProgramSetVertexAttribArray(0, true);
    gl.shaderProgramSetVertexAttribArray(1, true);

    gl.shaderProgramSetVertexAttribPointer(0, 2, f32, false, stride, @intToPtr(?*const c_void, @byteOffsetOf(Vertex2DNoTexture, "position")));
    gl.shaderProgramSetVertexAttribPointer(1, 4, f32, false, stride, @intToPtr(?*const c_void, @byteOffsetOf(Vertex2DNoTexture, "colour")));
}

fn pTextureShaderAttribs() void {
    const stride = @sizeOf(Vertex2DTexture);
    gl.shaderProgramSetVertexAttribArray(0, true);
    gl.shaderProgramSetVertexAttribArray(1, true);
    gl.shaderProgramSetVertexAttribArray(2, true);

    gl.shaderProgramSetVertexAttribPointer(0, 2, f32, false, stride, @intToPtr(?*const c_void, @byteOffsetOf(Vertex2DTexture, "position")));
    gl.shaderProgramSetVertexAttribPointer(1, 2, f32, false, stride, @intToPtr(?*const c_void, @byteOffsetOf(Vertex2DTexture, "texcoord")));
    gl.shaderProgramSetVertexAttribPointer(2, 4, f32, false, stride, @intToPtr(?*const c_void, @byteOffsetOf(Vertex2DTexture, "colour")));
}

fn pnoTextureSubmitQuadfn(self: *Batch2DQuadNoTexture, vertex: [Batch2DQuadNoTexture.max_vertex_count]Vertex2DNoTexture) renderer.Error!void {
    try psubmitVerticesQuad(Batch2DQuadNoTexture, self, vertex);
    try psubmitIndiciesQuad(Batch2DQuadNoTexture, self);

    self.submission_counter += 1;
}

fn pTextureSubmitQuadfn(self: *Batch2DQuadTexture, vertex: [Batch2DQuadTexture.max_vertex_count]Vertex2DTexture) renderer.Error!void {
    try psubmitVerticesQuad(Batch2DQuadTexture, self, vertex);
    try psubmitIndiciesQuad(Batch2DQuadTexture, self);

    self.submission_counter += 1;
}

fn psubmitVerticesQuad(comptime typ: type, self: *typ, vertex: [typ.max_vertex_count]typ.Vertex) renderer.Error!void {
    try self.submitVertex(self.submission_counter, 0, vertex[0]);
    try self.submitVertex(self.submission_counter, 1, vertex[1]);
    try self.submitVertex(self.submission_counter, 2, vertex[2]);
    try self.submitVertex(self.submission_counter, 3, vertex[3]);
}

fn psubmitIndiciesQuad(comptime typ: type, self: *typ) renderer.Error!void {
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
        while (i < typ.max_index_count) : (i += 1) {
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
            try self.submitIndex(self.submission_counter, i, back[i] + 4);
        }
    }
}

fn pcloseCallback(handle: ?*c_void) void {
    pwinrun = false;
}

fn presizeCallback(handle: ?*c_void, w: i32, h: i32) void {
    gl.viewport(0, 0, w, h);
}

fn keyboardCallback(handle: ?*c_void, key: i32, sc: i32, ac: i32, mods: i32) void {
    pinput.handleKeyboard(key, ac) catch unreachable;
}

fn mousebuttonCallback(handle: ?*c_void, key: i32, ac: i32, mods: i32) void {
    pinput.handleMButton(key, ac) catch unreachable;
}

fn mousePosCallback(handle: ?*c_void, x: f64, y: f64) void {
    pmouseX = @floatCast(f32, x);
    pmouseY = @floatCast(f32, y);
}

var pwin: *Window = undefined;
var pwinrun = false;
var pframetime = window.FrameTime{};
var pfps = window.FpsDirect{};
var pinput: *Input = undefined;
var pmouseX: f32 = 0;
var pmouseY: f32 = 0;
var pengineready = false;
var ptargetfps: f64 = 0.0;

var prenderer2D: *Renderer2D = undefined;

var pupdateproc: ?fn (deltatime: f32) anyerror!void = null;
var pfixedupdateproc: ?fn (fixedtime: f32) anyerror!void = null;
var pdraw2dproc: ?fn () anyerror!void = null;

var parena_alloc: std.heap.ArenaAllocator = undefined;

/// Initializes the engine
pub fn init(updatefn: ?fn (deltatime: f32) anyerror!void, fixedupdatefn: ?fn (fixedtime: f32) anyerror!void, draw2dfn: ?fn () anyerror!void, width: i32, height: i32, title: []const u8, fpslimit: u32) anyerror!void {
    if (pengineready) return Error.EngineIsInitialized;

    parena_alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var allocator = &parena_alloc.allocator;

    pwin = try allocator.create(Window);
    pinput = try allocator.create(Input);
    prenderer2D = try allocator.create(Renderer2D);

    try utils.initTimer();

    try utils.check((try utils.logCreateFile("kiragine.log")) == false, "kiragine -> failed to create log file!", .{});

    try glfw.init();
    glfw.resizable(false);
    glfw.initGLProfile();

    pwin.* = window.Info{};
    pwin.size.width = width;
    pwin.size.height = height;
    pwin.minsize = pwin.size;
    pwin.maxsize = pwin.size;
    pwin.title = title;
    pwin.callbacks.close = pcloseCallback;
    pwin.callbacks.resize = presizeCallback;
    pwin.callbacks.keyinp = keyboardCallback;
    pwin.callbacks.mouseinp = mousebuttonCallback;
    pwin.callbacks.mousepos = mousePosCallback;

    const sw = glfw.getScreenWidth();
    const sh = glfw.getScreenHeight();

    pwin.position.x = @divTrunc((sw - pwin.size.width), 2);
    pwin.position.y = @divTrunc((sh - pwin.size.height), 2);

    pinput.* = Input{};
    pinput.clearAllBindings();

    try pwin.create(false);
    glfw.makeContext(pwin.handle);
    gl.init();
    gl.setBlending(true);

    if (fpslimit == 0) {
        glfw.vsync(true);
    } else {
        glfw.vsync(false);
    }

    prenderer2D.* = Renderer2D{};
    prenderer2D.cam.ortho = Mat4x4f.ortho(0, @intToFloat(f32, pwin.size.width), @intToFloat(f32, pwin.size.height), 0, -1, 1);

    prenderer2D.notextureshader = try gl.shaderProgramCreate(std.heap.page_allocator, pnotexture_vertex_shader, pnotexture_fragment_shader);
    prenderer2D.textureshader = try gl.shaderProgramCreate(std.heap.page_allocator, ptexture_vertex_shader, ptexture_fragment_shader);

    try prenderer2D.quadbatch_notexture.create(prenderer2D.notextureshader, pnoTextureShaderAttribs);
    try prenderer2D.quadbatch_texture.create(prenderer2D.textureshader, pTextureShaderAttribs);

    pupdateproc = updatefn;
    pfixedupdateproc = fixedupdatefn;
    pdraw2dproc = draw2dfn;
    ptargetfps = 0;
    pengineready = true;

    try utils.printEndl(utils.LogLevel.info, "Kiragine initialized! Size -> width:{} & height:{} ; Title:{}", .{ pwin.size.width, pwin.size.height, pwin.title });
}

/// Deinitializes the engine
pub fn deinit() anyerror!void {
    if (!pengineready) return Error.EngineIsNotInitialized;

    prenderer2D.quadbatch_notexture.destroy();
    prenderer2D.quadbatch_texture.destroy();

    gl.shaderProgramDelete(prenderer2D.notextureshader);
    gl.shaderProgramDelete(prenderer2D.textureshader);

    try pwin.destroy();
    gl.deinit();

    glfw.deinit();
    try utils.printEndl(utils.LogLevel.info, "Kiragine deinitialized!", .{});
    try utils.check(utils.logCloseFile() == false, "kiragine -> failed to close log file!", .{});
    utils.deinitTimer();

    parena_alloc.deinit();
}

/// Opens the whole engine
pub fn open() anyerror!void {
    if (!pengineready) return Error.EngineIsNotInitialized;
    pwinrun = true;
}

/// Closes the whole engine
pub fn close() anyerror!void {
    if (!pengineready) return Error.EngineIsNotInitialized;
    pwinrun = false;
}

/// Updates the engine
pub fn update() anyerror!void {
    if (!pengineready) return Error.EngineIsNotInitialized;

    // Source: https://gafferongames.com/post/fix_your_timestep/
    var last: f64 = getElapsedTime();
    var accumulator: f64 = 0;
    var dt: f64 = 0.01;

    while (pwinrun) {
        pframetime.start();
        var ftime: f64 = pframetime.current - last;
        if (ftime > 0.25) {
            ftime = 0.25;
        }
        last = pframetime.current;
        accumulator += ftime;

        if (pupdateproc) |fun| {
            try fun(@floatCast(f32, pframetime.delta));
        }

        if (pfixedupdateproc) |fun| {
            while (accumulator >= dt) : (accumulator -= dt) {
                try fun(@floatCast(f32, dt));
            }
        }
        pinput.handle();

        if (pdraw2dproc) |fun| {
            try fun();
        }

        glfw.sync(pwin.handle);
        glfw.processEvents();

        pframetime.stop();
        pframetime.sleep(ptargetfps);

        pfps = pfps.calculate(pframetime);
    }
}

/// Clears the screen with given colour
pub fn clearScreen(r: f32, g: f32, b: f32, a: f32) void {
    gl.clearColour(r, g, b, a);
    gl.clearBuffers(gl.BufferBit.colour);
}

/// Returns the fps
pub fn getFps() u32 {
    return pfps.fps;
}

/// Returns the 2D camera
pub fn getCamera2D() *Camera2D {
    return &prenderer2D.cam;
}

/// Returns the window
pub fn getWindow() *Window {
    return pwin;
}

/// Returns the input
pub fn getInput() *Input {
    return pinput;
}

/// Returns the mouse pos x
pub fn getMouseX() *f32 {
    return pmouseX;
}

/// Returns the mouse pos y
pub fn getMouseY() *f32 {
    return pmouseY;
}

/// Enables the texture
pub fn enableTextureBatch2D(t: Texture) void {
    prenderer2D.current_texture = t;
    prenderer2D.textured = true;
}

/// Disables the texture
pub fn disableTextureBatch2D() void {
    prenderer2D.current_texture.id = 0;
    prenderer2D.textured = false;
}

/// Pushes the batch
pub fn pushBatch2D(tag: Renderer2DBatchTag) anyerror!void {
    prenderer2D.tag = tag;

    switch (prenderer2D.tag) {
        Renderer2DBatchTag.none => {
            return Error.InvalidRendererTag;
        },
        Renderer2DBatchTag.pixels => {
            if (prenderer2D.textured) return Error.InvalidBatch; // No textured lines
            prenderer2D.quadbatch_notexture.submitfn = pnoTextureSubmitQuadfn;
        },
        Renderer2DBatchTag.lines => {
            if (prenderer2D.textured) return Error.InvalidBatch; // No textured lines
            prenderer2D.quadbatch_notexture.submitfn = pnoTextureSubmitQuadfn;
        },
        Renderer2DBatchTag.triangles => {
            if (prenderer2D.textured) return Error.InvalidBatch; // No textured triangle
            prenderer2D.quadbatch_notexture.submitfn = pnoTextureSubmitQuadfn;
        },
        Renderer2DBatchTag.quad => {
            prenderer2D.quadbatch_texture.submitfn = pTextureSubmitQuadfn;
            prenderer2D.quadbatch_notexture.submitfn = pnoTextureSubmitQuadfn;
        },
    }

    var shader: u32 = 0;
    var mvploc: i32 = -1;
    if (!prenderer2D.textured) {
        shader = prenderer2D.notextureshader;
        try utils.check(shader == 0, "kiragine -> unable to use non-textured shader!", .{});

        mvploc = gl.shaderProgramGetUniformLocation(shader, "MVP");
        try utils.check(mvploc == -1, "kiragine -> unable to use uniforms from non-textured shader!", .{});
    } else {
        shader = prenderer2D.textureshader;
        try utils.check(shader == 0, "kiragine -> unable to use textured shader!", .{});

        mvploc = gl.shaderProgramGetUniformLocation(shader, "MVP");
        try utils.check(mvploc == -1, "kiragine -> unable to use uniforms from textured shader!", .{});
    }

    gl.shaderProgramUse(shader);

    prenderer2D.cam.attach();
    gl.shaderProgramSetMat4x4f(mvploc, @ptrCast([*]const f32, &prenderer2D.cam.view.toArray()));
}

/// Pops the batch
pub fn popBatch2D() anyerror!void {
    defer prenderer2D.cam.detach();
    defer prenderer2D.quadbatch_texture.submission_counter = 0;
    defer prenderer2D.quadbatch_notexture.submission_counter = 0;

    switch (prenderer2D.tag) {
        Renderer2DBatchTag.none => {},
        Renderer2DBatchTag.pixels => {
            if (prenderer2D.textured) {
                return Error.InvalidBatch;
            } else {
                try prenderer2D.quadbatch_notexture.draw(gl.DrawMode.points);
            }
        },
        Renderer2DBatchTag.lines => {
            if (prenderer2D.textured) {
                return Error.InvalidBatch;
            } else {
                try prenderer2D.quadbatch_notexture.draw(gl.DrawMode.lines);
            }
        },
        Renderer2DBatchTag.triangles => {
            if (prenderer2D.textured) {
                return Error.InvalidBatch;
            } else {
                try prenderer2D.quadbatch_notexture.draw(gl.DrawMode.triangles);
                prenderer2D.quadbatch_notexture.vertex_list = undefined;
                prenderer2D.quadbatch_notexture.index_list = undefined;
            }
        },
        Renderer2DBatchTag.quad => {
            if (prenderer2D.textured) {
                gl.textureBind(gl.TextureType.t2D, prenderer2D.current_texture.id);
                try prenderer2D.quadbatch_texture.draw(gl.DrawMode.triangles);
                gl.textureBind(gl.TextureType.t2D, 0);
                prenderer2D.quadbatch_texture.vertex_list = undefined;
                prenderer2D.quadbatch_texture.index_list = undefined;
            } else {
                try prenderer2D.quadbatch_notexture.draw(gl.DrawMode.triangles);
                prenderer2D.quadbatch_notexture.vertex_list = undefined;
                prenderer2D.quadbatch_notexture.index_list = undefined;
            }
        },
    }
}

/// Flushes the batch
pub fn flushBatch2D() anyerror!void {
    const tag = prenderer2D.tag;
    try popBatch2D();
    try pushBatch2D(tag);
}

/// Draws a pixel
pub fn drawPixel(pixel: Vec2f, colour: Colour) anyerror!void {
    switch (prenderer2D.tag) {
        Renderer2DBatchTag.quad, Renderer2DBatchTag.triangles, Renderer2DBatchTag.lines => {
            return Error.InvalidBatch;
        },
        else => {},
    }
    prenderer2D.quadbatch_notexture.submitDrawable([Batch2DQuadNoTexture.max_vertex_count]Vertex2DNoTexture{
        .{ .position = pixel, .colour = colour },
        .{ .position = pixel, .colour = colour },
        .{ .position = pixel, .colour = colour },
        .{ .position = pixel, .colour = colour },
    }) catch |err| {
        if (err == renderer.Error.ObjectOverflow) {
            try utils.printEndl(utils.LogLevel.warn, "kiragine -> pixel: failed to draw! Object overflow", .{});
            return Error.FailedToDraw;
        } else return err;
    };
}

/// Draws a line
pub fn drawLine(line0: Vec2f, line1: Vec2f, colour: Colour) anyerror!void {
    switch (prenderer2D.tag) {
        Renderer2DBatchTag.quad, Renderer2DBatchTag.triangles => {
            return Error.InvalidBatch;
        },
        else => {},
    }
    prenderer2D.quadbatch_notexture.submitDrawable([Batch2DQuadNoTexture.max_vertex_count]Vertex2DNoTexture{
        .{ .position = line0, .colour = colour },
        .{ .position = line1, .colour = colour },
        .{ .position = line1, .colour = colour },
        .{ .position = line1, .colour = colour },
    }) catch |err| {
        if (err == renderer.Error.ObjectOverflow) {
            try utils.printEndl(utils.LogLevel.warn, "kiragine -> line: failed to draw! Object overflow", .{});
            return Error.FailedToDraw;
        } else return err;
    };
}

/// Draws a triangle
pub fn drawTriangle(left: Vec2f, top: Vec2f, right: Vec2f, colour: Colour) anyerror!void {
    if (prenderer2D.textured) return Error.InvalidBatch;
    switch (prenderer2D.tag) {
        Renderer2DBatchTag.lines => {
            return Error.InvalidBatch;
        },
        else => {},
    }
    prenderer2D.quadbatch_notexture.submitDrawable([Batch2DQuadNoTexture.max_vertex_count]Vertex2DNoTexture{
        .{ .position = left, .colour = colour },
        .{ .position = top, .colour = colour },
        .{ .position = right, .colour = colour },
        .{ .position = right, .colour = colour },
    }) catch |err| {
        if (err == renderer.Error.ObjectOverflow) {
            try utils.printEndl(utils.LogLevel.warn, "kiragine -> triangle: failed to draw! Object overflow", .{});
            return Error.FailedToDraw;
        } else return err;
    };
}

/// Draws a rectangle
pub fn drawRectangle(rect: Rectangle, colour: Colour) anyerror!void {
    const pos0 = Vec2f{ .x = rect.x, .y = rect.y };
    const pos1 = Vec2f{ .x = rect.x + rect.width, .y = rect.y };
    const pos2 = Vec2f{ .x = rect.x + rect.width, .y = rect.y + rect.height };
    const pos3 = Vec2f{ .x = rect.x, .y = rect.y + rect.height };

    pdrawRectangle(pos0, pos1, pos2, pos3, colour) catch |err| {
        if (err == renderer.Error.ObjectOverflow) {
            try utils.printEndl(utils.LogLevel.warn, "kiragine -> rectangle: failed to draw! Object overflow", .{});
            return Error.FailedToDraw;
        } else return err;
    };
}

/// Draws a rectangle lines
pub fn drawRectangleLines(rect: Rectangle, colour: Colour) anyerror!void {
    try drawRectangle(.{ .x = rect.x, .y = rect.y, .width = rect.width, .height = 1 }, colour);
    try drawRectangle(.{ .x = rect.x + rect.width - 1, .y = rect.y + 1, .width = 1, .height = rect.height - 2 }, colour);
    try drawRectangle(.{ .x = rect.x, .y = rect.y + rect.height - 1, .width = rect.width, .height = 1 }, colour);
    try drawRectangle(.{ .x = rect.x, .y = rect.y + 1, .width = 1, .height = rect.height - 2 }, colour);
}

/// Draws a rectangle rotated(rotation should be provided in radians)
pub fn drawRectangleRotated(rect: Rectangle, origin: Vec2f, rotation: f32, colour: Colour) anyerror!void {
    var matrix = ModelMatrix{};
    matrix.translate(rect.x, rect.y, 0);
    matrix.translate(origin.x, origin.y, 0);
    matrix.rotate(0, 0, 1, rotation);
    matrix.translate(-origin.x, -origin.y, 0);
    const mvp = matrix.model;

    const r0 = Vec3f.transform(.{ .x = 0, .y = 0 }, mvp);
    const r1 = Vec3f.transform(.{ .x = rect.width, .y = 0 }, mvp);
    const r2 = Vec3f.transform(.{ .x = rect.width, .y = rect.height }, mvp);
    const r3 = Vec3f.transform(.{ .x = 0, .y = rect.height }, mvp);

    const pos0 = Vec2f{ .x = rect.x + r0.x, .y = rect.y + r0.y };
    const pos1 = Vec2f{ .x = rect.x + r1.x, .y = rect.y + r1.y };
    const pos2 = Vec2f{ .x = rect.x + r2.x, .y = rect.y + r2.y };
    const pos3 = Vec2f{ .x = rect.x + r3.x, .y = rect.y + r3.y };

    pdrawRectangle(pos0, pos1, pos2, pos3, colour) catch |err| {
        if (err == renderer.Error.ObjectOverflow) {
            try utils.printEndl(utils.LogLevel.warn, "kiragine -> rectangle: failed to draw! Object overflow", .{});
            return Error.FailedToDraw;
        } else return err;
    };
}

fn pdrawRectangle(pos0: Vec2f, pos1: Vec2f, pos2: Vec2f, pos3: Vec2f, colour: Colour) anyerror!void {
    if (prenderer2D.textured) return Error.InvalidBatch;
    switch (prenderer2D.tag) {
        Renderer2DBatchTag.lines => {
            return Error.InvalidBatch;
        },
        else => {},
    }
    try prenderer2D.quadbatch_notexture.submitDrawable([Batch2DQuadNoTexture.max_vertex_count]Vertex2DNoTexture{
        .{ .position = pos0, .colour = colour },
        .{ .position = pos1, .colour = colour },
        .{ .position = pos2, .colour = colour },
        .{ .position = pos3, .colour = colour },
    });
}

/// Draws a texture
pub fn drawTexture(rect: Rectangle, srcrect: Rectangle, colour: Colour) anyerror!void {
    const pos0 = Vec2f{ .x = rect.x, .y = rect.y };
    const pos1 = Vec2f{ .x = rect.x + rect.width, .y = rect.y };
    const pos2 = Vec2f{ .x = rect.x + rect.width, .y = rect.y + rect.height };
    const pos3 = Vec2f{ .x = rect.x, .y = rect.y + rect.height };

    pdrawTexture(pos0, pos1, pos2, pos3, srcrect, colour) catch |err| {
        if (err == renderer.Error.ObjectOverflow) {
            try utils.printEndl(utils.LogLevel.warn, "kiragine -> texture: failed to draw! Object overflow", .{});
            return Error.FailedToDraw;
        } else return err;
    };
}

/// Draws a texture(rotation should be provided in radians)
pub fn drawTextureRotated(rect: Rectangle, srcrect: Rectangle, origin: Vec2f, rotation: f32, colour: Colour) anyerror!void {
    var matrix = ModelMatrix{};
    matrix.translate(rect.x, rect.y, 0);
    matrix.translate(origin.x, origin.y, 0);
    matrix.rotate(0, 0, 1, rotation);
    matrix.translate(-origin.x, -origin.y, 0);
    const mvp = matrix.model;

    const r0 = Vec3f.transform(.{ .x = 0, .y = 0 }, mvp);
    const r1 = Vec3f.transform(.{ .x = rect.width, .y = 0 }, mvp);
    const r2 = Vec3f.transform(.{ .x = rect.width, .y = rect.height }, mvp);
    const r3 = Vec3f.transform(.{ .x = 0, .y = rect.height }, mvp);

    const pos0 = Vec2f{ .x = rect.x + r0.x, .y = rect.y + r0.y };
    const pos1 = Vec2f{ .x = rect.x + r1.x, .y = rect.y + r1.y };
    const pos2 = Vec2f{ .x = rect.x + r2.x, .y = rect.y + r2.y };
    const pos3 = Vec2f{ .x = rect.x + r3.x, .y = rect.y + r3.y };

    pdrawTexture(pos0, pos1, pos2, pos3, srcrect, colour) catch |err| {
        if (err == renderer.Error.ObjectOverflow) {
            try utils.printEndl(utils.LogLevel.warn, "kiragine -> texture: failed to draw! Object overflow", .{});
            return Error.FailedToDraw;
        } else return err;
    };
}

fn pdrawTexture(pos0: Vec2f, pos1: Vec2f, pos2: Vec2f, pos3: Vec2f, srcrect: Rectangle, colour: Colour) anyerror!void {
    if (!prenderer2D.textured) return Error.InvalidBatch;
    switch (prenderer2D.tag) {
        Renderer2DBatchTag.triangles, Renderer2DBatchTag.lines => {
            return Error.InvalidBatch;
        },
        else => {},
    }
    const width: f32 = @intToFloat(f32, prenderer2D.current_texture.width);
    const height: f32 = @intToFloat(f32, prenderer2D.current_texture.height);

    var src = srcrect;
    var flipX: bool = true;
    if (srcrect.width > 0) {
        flipX = false;
        src.width *= -1;
    }

    if (srcrect.height < 0) {
        src.y -= src.height;
    }

    const t0 = Vec2f{
        .x = if (flipX) src.x / width else (src.x + src.width) / width,
        .y = src.y / height,
    };

    const t1 = Vec2f{
        .x = if (flipX) (src.x + src.width) / width else src.x / width,
        .y = src.y / height,
    };

    const t2 = Vec2f{
        .x = if (flipX) (src.x + src.width) / width else src.x / width,
        .y = (src.y + src.height) / height,
    };

    const t3 = Vec2f{
        .x = if (flipX) src.x / width else (src.x + src.width) / width,
        .y = (src.y + src.height) / height,
    };

    try prenderer2D.quadbatch_texture.submitDrawable([Batch2DQuadTexture.max_vertex_count]Vertex2DTexture{
        .{ .position = pos0, .texcoord = t0, .colour = colour },
        .{ .position = pos1, .texcoord = t1, .colour = colour },
        .{ .position = pos2, .texcoord = t2, .colour = colour },
        .{ .position = pos3, .texcoord = t3, .colour = colour },
    });
}