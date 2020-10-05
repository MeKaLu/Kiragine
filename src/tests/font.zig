const std = @import("std");
const engine = @import("kiragine");
usingnamespace engine.kira.log;

const check = engine.check;
const kira = engine.kira;
const ft2 = kira.ft2;
const gl = kira.gl;
const c = kira.c;

const math = kira.math;

const Mat4x4f = math.mat4x4.Generic(f32);
const Vec3f = math.vec3.Generic(f32);

const vertexshader =
    \\#version 330 core
    \\layout (location = 0) in vec4 vertex; // <vec2 pos, vec2 tex>
    \\out vec2 TexCoords;
    \\
    \\uniform mat4 projection;
    \\
    \\void main()
    \\{
    \\    gl_Position = projection * vec4(vertex.xy, 0.0, 1.0);
    \\    TexCoords = vertex.zw;
    \\}
;

const fragmentshader =
    \\#version 330 core
    \\in vec2 TexCoords;
    \\out vec4 color;
    \\
    \\uniform sampler2D text;
    \\uniform vec3 textColor;
    \\
    \\void main()
    \\{    
    \\    vec4 sampled = vec4(1.0, 1.0, 1.0, texture(text, TexCoords).r);
    \\    color = vec4(textColor, 1.0) * sampled;
    \\}  
;

const Char = struct {
    textureid: u32 = 0,
    codepoint: u64 = 0,
    sizex: i32 = 0,
    sizey: i32 = 0,

    bearingx: i32 = 0,
    bearingy: i32 = 0,

    advance: i32 = 0,
};

var window_running = false;
var targetfps: f64 = 0;
var chars: std.ArrayList(Char) = undefined;

pub fn main() !void {
    try kira.glfw.init();
    defer kira.glfw.deinit();
    kira.glfw.resizable(false);
    kira.glfw.initGLProfile();

    var window = kira.window.Info{};
    var frametime = kira.window.FrameTime{};
    var fps = kira.window.FpsDirect{};
    window.title = "test-font";
    window.callbacks.close = closeCallback;
    window.callbacks.resize = resizeCallback;
    const sw = kira.glfw.getScreenWidth();
    const sh = kira.glfw.getScreenHeight();

    window.position.x = @divTrunc((sw - window.size.width), 2);
    window.position.y = @divTrunc((sh - window.size.height), 2);

    try window.create(false);
    defer window.destroy() catch unreachable;

    const ortho = Mat4x4f.ortho(0, @intToFloat(f32, window.size.width), @intToFloat(f32, window.size.height), 0, -1, 1);
    var cam = math.Camera2D{};
    cam.ortho = ortho;

    kira.glfw.makeContext(window.handle);
    kira.glfw.vsync(true);

    gl.init();
    defer gl.deinit();

    gl.setBlending(true);
    c.glPixelStorei(c.GL_UNPACK_ALIGNMENT, 1);

    var lib = ft2.Library{};
    try lib.init();

    var shader = try gl.shaderProgramCreate(std.heap.page_allocator, vertexshader, fragmentshader);
    defer gl.shaderProgramDelete(shader);

    chars = std.ArrayList(Char).init(std.heap.page_allocator);
    defer chars.deinit();
    var face = try ft2.Face.new(lib, "assets/Roboto/Roboto-Regular.ttf", 0);

    {
        var i: u64 = 0;
        while (i < 128) : (i += 1) {
            face.loadChar(i, ft2.Load.render) catch |err| {
                continue;
            };
            var glyph = face.base.*.glyph;
            var char = Char{
                .codepoint = i,
            };
            // NOTE: Do NOT forget to destroy it
            gl.texturesGen(1, @ptrCast([*]u32, &char.textureid));
            gl.textureBind(gl.TextureType.t2D, char.textureid);
            gl.textureTexImage2D(gl.TextureType.t2D, 0, gl.TextureFormat.red, @intCast(i32, glyph.*.bitmap.width), @intCast(i32, glyph.*.bitmap.rows), 0, gl.TextureFormat.red, u8, glyph.*.bitmap.buffer);

            gl.textureTexParameteri(gl.TextureType.t2D, gl.TextureParamaterType.wrap_s, gl.TextureParamater.wrap_clamp_to_edge);
            gl.textureTexParameteri(gl.TextureType.t2D, gl.TextureParamaterType.wrap_t, gl.TextureParamater.wrap_clamp_to_edge);
            gl.textureTexParameteri(gl.TextureType.t2D, gl.TextureParamaterType.min_filter, gl.TextureParamater.filter_linear);
            gl.textureTexParameteri(gl.TextureType.t2D, gl.TextureParamaterType.mag_filter, gl.TextureParamater.filter_linear);

            try chars.append(char);
        }
        gl.textureBind(gl.TextureType.t2D, 0);
    }

    try face.destroy();
    try lib.deinit();

    var vao: u32 = 0;
    var vbo: u32 = 0;
    // NOTE: Do NOT forget to destroy it
    gl.vertexArraysGen(1, @ptrCast([*]u32, &vao));
    gl.buffersGen(1, @ptrCast([*]u32, &vbo));
    defer gl.vertexArraysDelete(1, @ptrCast([*]const u32, &vao));
    defer gl.buffersDelete(1, @ptrCast([*]const u32, &vbo));

    {
        gl.shaderProgramUse(shader);
        defer gl.shaderProgramUse(0);
        gl.vertexArrayBind(vao);
        gl.bufferBind(gl.BufferType.array, vbo);
        defer gl.bufferBind(gl.BufferType.array, 0);
        defer gl.vertexArrayBind(0);

        gl.bufferData(gl.BufferType.array, @sizeOf(f32) * 6 * 4, null, gl.DrawType.dynamic);

        gl.shaderProgramSetVertexAttribArray(0, true);
        gl.shaderProgramSetVertexAttribPointer(0, 4, f32, false, 4 * @sizeOf(f32), null);
    }

    window_running = true;
    while (window_running) {
        frametime.start();
        defer {
            kira.glfw.sync(window.handle);
            kira.glfw.processEvents();

            frametime.stop();
            frametime.sleep(targetfps);

            fps = fps.calculate(frametime);
            std.log.notice("FPS: {}", .{fps.fps});
        }

        gl.clearColour(0.1, 0.1, 0.1, 1.0);
        gl.clearBuffers(gl.BufferBit.colour);

        cam.attach();
        const mvp = @ptrCast([*]const f32, &cam.view.toArray());

        {
            gl.shaderProgramUse(shader);
            defer gl.shaderProgramUse(0);
            gl.vertexArrayBind(vao);
            defer gl.vertexArrayBind(0);
            gl.bufferBind(gl.BufferType.array, vbo);
            defer gl.bufferBind(gl.BufferType.array, 0);

            const loc = gl.shaderProgramGetUniformLocation(shader, "projection");
            try check(loc == -1, "fuck", .{});
            gl.shaderProgramSetMat4x4f(loc, mvp);

            const loc2 = gl.shaderProgramGetUniformLocation(shader, "textColor");
            try check(loc2 == -1, "fuck2", .{});
            var col = engine.Colour{ .r = 1, .g = 1, .b = 1, .a = 1 };
            gl.shaderProgramSetVec3f(loc2, @ptrCast([*]const f32, &col));

            try renderText("Hello", 200, 200, 24, 24);
        }

        cam.detach();
    }
}

// Does not work?
fn renderText(text: []const u8, x: f32, y: f32, sx: f32, sy: f32) !void {
    var i: u32 = 0;
    var cc: u64 = 0;
    var ix = x;
    c.glActiveTexture(c.GL_TEXTURE0);
    defer gl.textureBind(gl.TextureType.t2D, 0);

    while (i < text.len) : (i += 1) {
        cc = text[i];
        var j: u32 = 0;
        const ch = chars.items;
        while (j < ch.len) : (j += 1) {
            if (cc == ch[j].codepoint) break;
        }
        //std.log.warn("codepoint: {}", .{cc});
        var char = ch[j];
        const xp = ix + @intToFloat(f32, char.bearingx) * sx;
        const yp = y - @intToFloat(f32, (char.sizey - char.bearingy)) * sy;
        const w = @intToFloat(f32, char.sizex) * sx;
        const h = @intToFloat(f32, char.sizey) * sy;

        var vertices = [6][4]f32{
            [4]f32{ xp, yp + h, 0, 0 },
            [4]f32{ xp, yp, 0, 1 },
            [4]f32{ xp + w, yp, 1, 1 },

            [4]f32{ xp, yp + h, 0, 0 },
            [4]f32{ xp + w, yp, 1, 1 },
            [4]f32{ xp + w, yp + h, 1, 0 },
        };

        gl.textureBind(gl.TextureType.t2D, char.textureid);
        gl.bufferSubData(gl.BufferType.array, 0, @sizeOf(f32) * 6 * 4, @ptrCast(?*const c_void, &vertices));
        gl.drawArrays(gl.DrawMode.triangles, 0, 6);
        ix += @intToFloat(f32, (char.advance >> 6)) * sx;
    }
}

fn closeCallback(handle: ?*c_void) void {
    window_running = false;
}

fn resizeCallback(handle: ?*c_void, w: i32, h: i32) void {
    gl.viewport(0, 0, w, h);
}
