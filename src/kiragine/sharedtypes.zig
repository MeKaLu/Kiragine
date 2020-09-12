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

const cam = @import("kira/math/camera.zig");
const mat4x4 = @import("kira/math/mat4x4.zig");
const math = @import("kira/math/common.zig");
const vec2 = @import("kira/math/vec2.zig");
const vec3 = @import("kira/math/vec3.zig");

const glfw = @import("kira/glfw.zig");
const renderer = @import("kira/renderer.zig");
const input = @import("kira/input.zig");
const window = @import("kira/window.zig");
const gl = @import("kira/gl.zig");
const c = @import("kira/c.zig");

const utils = @import("kira/utils.zig");

pub const Mat4x4f = mat4x4.Generic(f32);
pub const Vec2f = vec2.Generic(f32);
pub const Vec3f = vec3.Generic(f32);

pub const Window = window.Info;
pub const Input = input.Info;

pub const Camera2D = cam.Camera2D;
pub const Colour = renderer.ColourGeneric(f32);
pub const UColour = renderer.ColourGeneric(u8);

/// Private Error set
const pError = error{
    /// Engine is not initialized, initialize it before using the engine
    EngineIsNotInitialized,
    /// Engine is initialized, cannot initialize it again
    EngineIsInitialized,
    /// Current batch cannot able to do thing you are just about to do
    InvalidBatch,
    /// Failes to load texture
    FailedToLoadTexture,
    /// Current batch has filled, cannot able to draw anymore
    FailedToDraw,
    /// Texture is not available or corrupted
    InvalidTexture,
    /// Custom batch already enabled
    UnableToEnableCustomBatch,

    // Merge input errors

    /// Binding is not available
    InvalidBinding,
    /// Binding list has filled, cannot able to bind anymore
    NoEmptyBinding,

    // Merge kira errors

    /// Check has failed(expression was true)
    CheckFailed,

    // Merge glfw errors

    /// GLFW failed to initialize, check logs!
    GLFWFailedToInitialize,

    // Merge renderer errors

    /// OpenGL failes to generate vbo, vao, ebo
    FailedToGenerateBuffers,
    /// Object list has been reached it's limits
    /// and you are trying to write into it
    ObjectOverflow,
    /// Vertex list has been reached it's limits
    /// and you are trying to write into it
    VertexOverflow,
    /// Index list has been reached it's limits
    /// and you are trying to write into it
    IndexOverflow,
    /// Submit fn is not initialized
    /// and you are trying to execute it
    UnknownSubmitFn,
};

/// Error set
pub const Error = pError || input.Error || utils.Error || glfw.Error || renderer.Error;

/// Helper type for using MVP's
pub const ModelMatrix = struct {
    model: Mat4x4f = Mat4x4f.identity(),
    trans: Mat4x4f = Mat4x4f.identity(),
    rot: Mat4x4f = Mat4x4f.identity(),
    sc: Mat4x4f = Mat4x4f.identity(),

    /// Apply the changes were made
    pub fn update(self: *ModelMatrix) void {
        self.model = Mat4x4f.mul(self.sc, Mat4x4f.mul(self.trans, self.rot));
    }

    /// Translate the matrix 
    pub fn translate(self: *ModelMatrix, x: f32, y: f32, z: f32) void {
        self.trans = Mat4x4f.translate(x, y, z);
        self.update();
    }

    /// Rotate the matrix 
    pub fn rotate(self: *ModelMatrix, x: f32, y: f32, z: f32, angle: f32) void {
        self.rot = Mat4x4f.rotate(x, y, z, angle);
        self.update();
    }

    /// Scale the matrix 
    pub fn scale(self: *ModelMatrix, x: f32, y: f32, z: f32) void {
        self.sc = Mat4x4f.scale(x, y, z);
        self.update();
    }
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
    pub fn createFromPNG(path: []const u8) Error!Texture {
        var result = Texture{};
        result.loadSetup();
        defer gl.textureBind(gl.TextureType.t2D, 0);

        var nrchannels: i32 = 0;

        c.stbi_set_flip_vertically_on_load(0);
        var data: ?*u8 = c.stbi_load(@ptrCast([*c]const u8, path), &result.width, &result.height, &nrchannels, 4);
        defer c.stbi_image_free(data);

        if (data == null) {
            gl.texturesDelete(1, @ptrCast([*]u32, &result.id));
            return Error.FailedToLoadTexture;
        }

        gl.textureTexImage2D(gl.TextureType.t2D, 0, gl.TextureFormat.rgba8, result.width, result.height, 0, gl.TextureFormat.rgba, u8, data);

        return result;
    }

    /// Creates a texture from png memory
    pub fn createFromPNGMemory(mem: []const u8) Error!Texture {
        var result = Texture{};
        result.loadSetup();
        defer gl.textureBind(gl.TextureType.t2D, 0);

        var nrchannels: i32 = 0;

        c.stbi_set_flip_vertically_on_load(0);
        var data: ?*u8 = c.stbi_load_from_memory(@ptrCast([*c]const u8, mem), @intCast(i32, mem.len), &result.width, &result.height, &nrchannels, 4);
        defer c.stbi_image_free(data);

        if (data == null) {
            gl.texturesDelete(1, @ptrCast([*]u32, &result.id));
            return Error.FailedToLoadTexture;
        }

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