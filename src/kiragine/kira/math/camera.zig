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

const vec2 = @import("vec2.zig");
const vec3 = @import("vec3.zig");
const mat4x4 = @import("mat4x4.zig");

const Vec2f = vec2.Generic(f32);
const Vec3f = vec3.Generic(f32);
const Mat4x4f = mat4x4.Generic(f32);

/// 2D Camera
pub const Camera2D = struct {
    position: Vec2f = Vec2f{ .x = 0, .y = 0 },
    offset: Vec2f = Vec2f{ .x = 0, .y = 0 },
    zoom: Vec2f = Vec2f{ .x = 1, .y = 1 },

    /// In radians
    rotation: f32 = 0,

    ortho: Mat4x4f = comptime Mat4x4f.identity(),
    view: Mat4x4f = comptime Mat4x4f.identity(),

    /// Returns the camera matrix
    pub fn matrix(self: Camera2D) Mat4x4f {
        const origin = Mat4x4f.translate(self.position.x, self.position.y, 0);
        const rot = Mat4x4f.rotate(0, 0, 1, self.rotation);
        const scale = Mat4x4f.scale(self.zoom.x, self.zoom.y, 0);
        const offset = Mat4x4f.translate(self.offset.x, self.offset.y, 0);

        return Mat4x4f.mul(Mat4x4f.mul(origin, Mat4x4f.mul(scale, rot)), offset);
    }

    /// Attaches the camera
    pub fn attach(self: *Camera2D) void {
        self.view = Mat4x4f.mul(self.matrix(), self.ortho);
    }

    /// Detaches the camera
    pub fn detach(self: *Camera2D) void {
        self.view = Mat4x4f.identity();
    }

    /// Returns the screen space position for a 2d camera world space position
    pub fn worldToScreen(self: Camera2D, position: Vec2f) Vec2f {
        const m = self.matrix();
        const v = Vec3f.transform(Vec3f{ .x = position.x, .y = position.y, .z = 0.0 }, m);
        return .{ .x = v.x, .y = v.y };
    }

    /// Returns the world space position for a 2d camera screen space position
    pub fn screenToWorld(self: Camera2D, position: Vec2f) Vec2f {
        const m = Mat4x4f.invert(self.matrix());
        const v = Vec3f.transform(Vec3f{ .x = position.x, .y = position.y, .z = 0.0 }, m);
        return .{ .x = v.x, .y = v.y };
    }
};
