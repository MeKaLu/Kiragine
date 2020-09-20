// -----------------------------------------
// |           Kiragine 1.1.0              |
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
const utils = @import("utils.zig");
const std = @import("std");
usingnamespace @import("log.zig");

// DEF

/// Buffer bits
pub const BufferBit = enum {
    depth, stencil, colour
};

/// Buffer types
pub const BufferType = enum {
    array, elementarray
};

/// Draw types
pub const DrawType = enum {
    static, dynamic, stream
};

/// Draw modes
pub const DrawMode = enum {
    points = 0x0000,
    lines = 0x0001,
    lineloop = 0x0002,
    linestrip = 0x0003,
    triangles = 0x0004,
    trianglestrip = 0x0005,
    trianglefan = 0x0006,
};

/// Shader types
pub const ShaderType = enum {
    vertex, fragment, geometry
};

/// Texture types
pub const TextureType = enum {
    t2D,
};

// zig fmt: off
/// Texture formats
pub const TextureFormat = enum {
    rgb, rgb8, rgb32f, rgba, rgba8, rgba32f, 
    red, alpha
};
// zig fmt: on

/// Texture paramater types
pub const TextureParamaterType = enum {
    min_filter,
    mag_filter,
    wrap_s,
    wrap_t,
    wrap_r,
};

/// Texture paramater
pub const TextureParamater = enum {
    filter_linear,
    filter_nearest,
    wrap_repeat,
    wrap_mirrored_repeat,
    wrap_clamp_to_edge,
    wrap_clamp_to_border,
};

// ENDDEF

// COMMON

/// Initializes OpenGL(GLAD)
pub fn init() void {
    _ = c.gladLoaderLoadGL();
}

/// Deinitializes OpenGL(GLAD)
pub fn deinit() void {
    c.gladLoaderUnloadGL();
}

/// Specifies the red, green, blue, and alpha values used by clearBuffers to clear the colour buffers.
/// Values are clamped to the range [0,1].
pub fn clearColour(r: f32, g: f32, b: f32, a: f32) void {
    c.glClearColor(r, g, b, a);
}

/// Clear buffers to preset values
pub fn clearBuffers(comptime bit: BufferBit) void {
    c.glClear(pdecideBufferBit(bit));
}

/// Set the viewport
pub fn viewport(x: i32, y: i32, w: i32, h: i32) void {
    c.glViewport(x, y, w, h);
}

/// Set the ortho
pub fn ortho(l: f32, r: f32, b: f32, t: f32, nr: f32, fr: f32) void {
    c.glOrtho(l, r, b, t, nr, fr);
}

/// Render primitives from array data
pub fn drawArrays(mode: DrawMode, first: i32, count: i32) void {
    c.glDrawArrays(@enumToInt(mode), first, count);
}

/// Render primitives from array data
pub fn drawElements(mode: DrawMode, size: i32, comptime typ: type, indices: ?*const c_void) void {
    const t = comptime pdecideGLTYPE(typ);
    c.glDrawElements(@enumToInt(mode), size, t, indices);
}

/// Enables/Disables the blending
pub fn setBlending(status: bool) void {
    if (status) {
        c.glEnable(c.GL_BLEND);
        c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);
    } else c.glDisable(c.GL_BLEND);
}

// ENDCOMMON

// BUFFERS

/// Generate vertex array object names
pub fn vertexArraysGen(n: i32, arrays: [*]u32) void {
    c.glGenVertexArrays(n, arrays);
}

/// Delete vertex array objects
pub fn vertexArraysDelete(n: i32, arrays: [*]const u32) void {
    c.glDeleteVertexArrays(n, arrays);
}

/// Generate buffer object names
pub fn buffersGen(n: i32, arrays: [*]u32) void {
    c.glGenBuffers(n, arrays);
}

/// Delete named buffer objects
pub fn buffersDelete(n: i32, arrays: [*]const u32) void {
    c.glDeleteBuffers(n, arrays);
}

/// Bind a vertex array object
pub fn vertexArrayBind(array: u32) void {
    c.glBindVertexArray(array);
}

/// Bind a named buffer object
pub fn bufferBind(comptime target: BufferType, buffer: u32) void {
    c.glBindBuffer(pdecideBufferType(target), buffer);
}

/// Creates and initializes a buffer object's data store
pub fn bufferData(comptime target: BufferType, size: u32, data: ?*const c_void, comptime usage: DrawType) void {
    c.glBufferData(pdecideBufferType(target), size, data, pdecideDrawType(usage));
}

/// Updates a subset of a buffer object's data store
pub fn bufferSubData(comptime target: BufferType, offset: i32, size: u32, data: ?*const c_void) void {
    c.glBufferSubData(pdecideBufferType(target), offset, size, data);
}

// ENDBUFFERS

// SHADER

/// Creates a shader
pub fn shaderCreateBasic(comptime typ: ShaderType) u32 {
    return c.glCreateShader(pdecideShaderType(typ));
}

/// Deletes the shader
pub fn shaderDelete(sh: u32) void {
    c.glDeleteShader(sh);
}

/// Compiles the shader source with given shader type
pub fn shaderCompile(alloc: *std.mem.Allocator, source: []const u8, comptime typ: ShaderType) !u32 {
    var result: u32 = shaderCreateBasic(typ);
    c.glShaderSource(result, 1, @ptrCast([*]const [*]const u8, &source), null);
    c.glCompileShader(result);

    var fuck: i32 = 0;
    c.glGetShaderiv(result, c.GL_COMPILE_STATUS, &fuck);
    if (fuck == 0) {
        var len: i32 = 0;
        c.glGetShaderiv(result, c.GL_INFO_LOG_LENGTH, &len);
        var msg = try alloc.alloc(u8, @intCast(usize, len));

        c.glGetShaderInfoLog(result, len, &len, @ptrCast([*c]u8, msg));

        std.log.alert("{}: {}", .{ source, msg });
        shaderDelete(result);
        alloc.free(msg);
        try utils.check(true, "kira/gl -> unable to compile shader!", .{});
    }
    return result;
}

/// Creates a program object
pub fn shaderProgramCreateBasic() u32 {
    return c.glCreateProgram();
}

/// Creates a program object from vertex and fragment source
pub fn shaderProgramCreate(alloc: *std.mem.Allocator, vertex: []const u8, fragment: []const u8) !u32 {
    const vx = try shaderCompile(alloc, vertex, ShaderType.vertex);
    const fg = try shaderCompile(alloc, fragment, ShaderType.fragment);
    defer {
        shaderDelete(vx);
        shaderDelete(fg);
    }

    const result = shaderProgramCreateBasic();
    shaderAttach(result, vx);
    shaderAttach(result, fg);
    shaderProgramLink(result);
    shaderProgramValidate(result);

    return result;
}

/// Deletes a program object
pub fn shaderProgramDelete(pr: u32) void {
    c.glDeleteProgram(pr);
}

/// Installs a program object as part of current rendering state
pub fn shaderProgramUse(pr: u32) void {
    c.glUseProgram(pr);
}

/// Attaches a shader object to a program object
pub fn shaderAttach(pr: u32, sh: u32) void {
    c.glAttachShader(pr, sh);
}

/// Links a program object
pub fn shaderProgramLink(pr: u32) void {
    c.glLinkProgram(pr);
}

/// Validates a program object
pub fn shaderProgramValidate(pr: u32) void {
    c.glValidateProgram(pr);
}

/// Get uniform location from shader object
pub fn shaderProgramGetUniformLocation(sh: u32, name: []const u8) i32 {
    return c.glGetUniformLocation(sh, @ptrCast([*c]const u8, name));
}

/// Sets the int data
pub fn shaderProgramSetInt(loc: i32, value: i32) void {
    c.glUniform1i(loc, value);
}

/// Sets the float data
pub fn shaderProgramSetFloat(loc: i32, value: f32) void {
    c.glUniform1f(loc, value);
}

/// Sets the vec2 data
pub fn shaderProgramSetVec2f(loc: i32, value: [*]const f32) void {
    c.glUniform2fv(loc, 1, value);
}

/// Sets the vec3 data
pub fn shaderProgramSetVec3f(loc: i32, value: [*]const f32) void {
    c.glUniform3fv(loc, 1, value);
}

/// Sets the matrix data
pub fn shaderProgramSetMat4x4f(loc: i32, data: [*]const f32) void {
    c.glUniformMatrix4fv(loc, 1, c.GL_FALSE, data);
}

/// Enable or disable a generic vertex attribute array
pub fn shaderProgramSetVertexAttribArray(index: u32, status: bool) void {
    if (status) {
        c.glEnableVertexAttribArray(index);
    } else {
        c.glDisableVertexAttribArray(index);
    }
}

/// Define an array of generic vertex attribute data
pub fn shaderProgramSetVertexAttribPointer(index: u32, size: i32, comptime typ: type, normalize: bool, stride: i32, ptr: ?*const c_void) void {
    const t = comptime pdecideGLTYPE(typ);
    c.glVertexAttribPointer(index, size, t, if (normalize) c.GL_TRUE else c.GL_FALSE, stride, ptr);
}

// ENDSHADER

// TEXTURE

/// Generate texture names
pub fn texturesGen(count: i32, textures: [*]u32) void {
    c.glGenTextures(count, textures);
}

/// Delete named textures
pub fn texturesDelete(count: i32, textures: [*]const u32) void {
    c.glDeleteTextures(count, textures);
}

/// Generate mipmaps for a specified texture target
pub fn texturesGenMipmap(comptime target: TextureType) void {
    c.glGenMipmap(pdecideTextureType(target));
}

/// Bind a named texture to a texturing target
pub fn textureBind(comptime target: TextureType, texture: u32) void {
    c.glBindTexture(pdecideTextureType(target), texture);
}

/// Specify a two-dimensional texture image
pub fn textureTexImage2D(comptime target: TextureType, level: i32, comptime internalformat: TextureFormat, width: i32, height: i32, border: i32, comptime format: TextureFormat, comptime typ: type, data: ?*c_void) void {
    c.glTexImage2D(pdecideTextureType(target), level, @intCast(i32, pdecideTextureFormat(internalformat)), width, height, border, pdecideTextureFormat(format), pdecideGLTYPE(typ), data);
}

/// Set texture parameters
pub fn textureTexParameteri(comptime target: TextureType, comptime pname: TextureParamaterType, comptime param: TextureParamater) void {
    c.glTexParameteri(pdecideTextureType(target), pdecideTextureParamType(pname), pdecideTextureParam(param));
}

// ENDTEXTURE

// PRIVATE

/// Decides the buffer bit type from given BufferBit
fn pdecideBufferBit(comptime typ: BufferBit) u32 {
    switch (typ) {
        BufferBit.depth => return c.GL_DEPTH_BUFFER_BIT,
        BufferBit.stencil => return c.GL_STENCIL_BUFFER_BIT,
        BufferBit.colour => return c.GL_COLOR_BUFFER_BIT,
    }
}

/// Decides the buffer type from given BufferType
fn pdecideBufferType(comptime typ: BufferType) u32 {
    switch (typ) {
        BufferType.array => return c.GL_ARRAY_BUFFER,
        BufferType.elementarray => return c.GL_ELEMENT_ARRAY_BUFFER,
    }
}

/// Decides the draw type from given DrawType
fn pdecideDrawType(comptime typ: DrawType) u32 {
    switch (typ) {
        DrawType.static => return c.GL_STATIC_DRAW,
        DrawType.dynamic => return c.GL_DYNAMIC_DRAW,
        DrawType.stream => return c.GL_STREAM_DRAW,
    }
}

/// Decides the Shader type from given ShaderType
fn pdecideShaderType(comptime typ: ShaderType) u32 {
    switch (typ) {
        ShaderType.vertex => return c.GL_VERTEX_SHADER,
        ShaderType.fragment => return c.GL_FRAGMENT_SHADER,
        ShaderType.geometry => return c.GL_GEOMETRY_SHADER,
    }
}

/// Decides the Texture type from given TextureType
fn pdecideTextureType(comptime typ: TextureType) u32 {
    switch (typ) {
        TextureType.t2D => return c.GL_TEXTURE_2D,
    }
}

/// Decides the Texture format from given TextureFormat
fn pdecideTextureFormat(comptime typ: TextureFormat) u32 {
    switch (typ) {
        TextureFormat.rgb => return c.GL_RGB,
        TextureFormat.rgb8 => return c.GL_RGB8,
        TextureFormat.rgb32f => return c.GL_RGB32F,
        TextureFormat.rgba => return c.GL_RGBA,
        TextureFormat.rgba8 => return c.GL_RGBA8,
        TextureFormat.rgba32f => return c.GL_RGBA32F,
        TextureFormat.red => return c.GL_RED,
        TextureFormat.alpha => return c.GL_ALPHA,
    }
}

/// Decides the Texture parameter type from given TextureParamaterType
fn pdecideTextureParamType(comptime typ: TextureParamaterType) u32 {
    switch (typ) {
        TextureParamaterType.min_filter => return c.GL_TEXTURE_MIN_FILTER,
        TextureParamaterType.mag_filter => return c.GL_TEXTURE_MAG_FILTER,
        TextureParamaterType.wrap_s => return c.GL_TEXTURE_WRAP_S,
        TextureParamaterType.wrap_t => return c.GL_TEXTURE_WRAP_T,
        TextureParamaterType.wrap_r => return c.GL_TEXTURE_WRAP_R,
    }
}

/// Decides the Texture parameter from given TextureParamater
fn pdecideTextureParam(comptime typ: TextureParamater) i32 {
    switch (typ) {
        TextureParamater.filter_linear => return c.GL_LINEAR,
        TextureParamater.filter_nearest => return c.GL_NEAREST,
        TextureParamater.wrap_repeat => return c.GL_REPEAT,
        TextureParamater.wrap_mirrored_repeat => return c.GL_MIRRORED_REPEAT,
        TextureParamater.wrap_clamp_to_edge => return c.GL_CLAMP_TO_EDGE,
        TextureParamater.wrap_clamp_to_border => return c.GL_CLAMP_TO_BORDER,
    }
}

/// Decides the GL_TYPE from given zig type
fn pdecideGLTYPE(comptime typ: type) u32 {
    switch (typ) {
        u8 => return c.GL_UNSIGNED_BYTE,
        u32 => return c.GL_UNSIGNED_INT,
        i32 => return c.GL_INT,
        f32 => return c.GL_FLOAT,
        else => @compileError("Unknown gl type"),
    }
}

// ENDPRIVATE
