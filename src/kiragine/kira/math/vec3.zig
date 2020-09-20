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

const mat4x4 = @import("mat4x4.zig");

/// Generic Vector3 Type
pub fn Generic(comptime T: type) type {
    switch (T) {
        i16, i32, i64, i128, f16, f32, f64, f128 => {
            return struct {
                const Self = @This();
                /// X value
                x: T = 0,
                /// Y value
                y: T = 0,
                /// Z value
                z: T = 0,

                /// Adds two Vector3s and returns the result
                pub fn add(self: Self, other: Self) Self {
                    return .{ .x = self.x + other.x, .y = self.y + other.y, .z = self.z + other.z };
                }

                /// Add values to the self and returns the result
                pub fn addValues(self: Self, x: T, y: T, z: T) Self {
                    return .{ .x = self.x + x, .y = self.y + y, .z = self.z + z };
                }

                /// Subtracts two Vector3s and returns the result
                pub fn sub(self: Self, other: Self) Self {
                    return .{ .x = self.x - other.x, .y = self.y - other.y, .z = self.z - other.z };
                }

                /// Subtract values to the self and returns the result
                pub fn subValues(self: Self, x: T, y: T, z: T) Self {
                    return .{ .x = self.x - x, .y = self.y - y, .z = self.z - z };
                }

                /// Divides two Vector3s and returns the result
                pub fn div(self: Self, other: Self) Self {
                    return .{ .x = self.x / other.x, .y = self.y / other.y, .z = self.z / other.z };
                }

                /// Divide values to the self and returns the result
                pub fn divValues(self: Self, x: T, y: T, z: T) Self {
                    return .{ .x = self.x / x, .y = self.y / y, .z = self.z / z };
                }

                /// Multiplies two Vector3s and returns the result
                pub fn mul(self: Self, other: Self) Self {
                    return .{ .x = self.x * other.x, .y = self.y * other.y, .z = self.z * other.z };
                }

                /// Multiply values to the self and returns the result
                pub fn mulValues(self: Self, x: T, y: T, z: T) Self {
                    return .{ .x = self.x * x, .y = self.y * y, .z = self.z * z };
                }

                /// Transforms a Vector3 by a given 4x4 Matrix
                pub fn transform(v1: Self, mat: mat4x4.Generic(T)) Self {
                    const x = v1.x;
                    const y = v1.y;
                    const z = v1.z;

                    return Self{
                        .x = mat.m0 * x + mat.m4 * y + mat.m8 * z + mat.m12,
                        .y = mat.m1 * x + mat.m5 * y + mat.m9 * z + mat.m13,
                        .z = mat.m2 * x + mat.m6 * y + mat.m10 * z + mat.m14,
                    };
                }
            };
        },
        else => @compileError("Vector3 not implemented for " ++ @typeName(T)),
    }
}
