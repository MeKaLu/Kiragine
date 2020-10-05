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

const cos = @import("std").math.cos;
const sqrt = @import("std").math.sqrt;
const sin = @import("std").math.sin;

/// Generic Matrix4x4 Type, right handed column major
pub fn Generic(comptime T: type) type {
    switch (T) {
        f16, f32, f64, f128, i16, i32, i64, i128 => {
            return struct {
                const Self = @This();
                m0: T = 0,
                m4: T = 0,
                m8: T = 0,
                m12: T = 0,
                m1: T = 0,
                m5: T = 0,
                m9: T = 0,
                m13: T = 0,
                m2: T = 0,
                m6: T = 0,
                m10: T = 0,
                m14: T = 0,
                m3: T = 0,
                m7: T = 0,
                m11: T = 0,
                m15: T = 0,

                /// Returns identity matrix
                pub fn identity() Self {
                    return .{
                        .m0 = 1,
                        .m4 = 0,
                        .m8 = 0,
                        .m12 = 0,
                        .m1 = 0,
                        .m5 = 1,
                        .m9 = 0,
                        .m13 = 0,
                        .m2 = 0,
                        .m6 = 0,
                        .m10 = 1,
                        .m14 = 0,
                        .m3 = 0,
                        .m7 = 0,
                        .m11 = 0,
                        .m15 = 1,
                    };
                }

                /// Multiplies the matrices, returns the result
                pub fn mul(left: Self, right: Self) Self {
                    return .{
                        .m0 = left.m0 * right.m0 + left.m1 * right.m4 + left.m2 * right.m8 + left.m3 * right.m12,
                        .m1 = left.m0 * right.m1 + left.m1 * right.m5 + left.m2 * right.m9 + left.m3 * right.m13,
                        .m2 = left.m0 * right.m2 + left.m1 * right.m6 + left.m2 * right.m10 + left.m3 * right.m14,
                        .m3 = left.m0 * right.m3 + left.m1 * right.m7 + left.m2 * right.m11 + left.m3 * right.m15,
                        .m4 = left.m4 * right.m0 + left.m5 * right.m4 + left.m6 * right.m8 + left.m7 * right.m12,
                        .m5 = left.m4 * right.m1 + left.m5 * right.m5 + left.m6 * right.m9 + left.m7 * right.m13,
                        .m6 = left.m4 * right.m2 + left.m5 * right.m6 + left.m6 * right.m10 + left.m7 * right.m14,
                        .m7 = left.m4 * right.m3 + left.m5 * right.m7 + left.m6 * right.m11 + left.m7 * right.m15,
                        .m8 = left.m8 * right.m0 + left.m9 * right.m4 + left.m10 * right.m8 + left.m11 * right.m12,
                        .m9 = left.m8 * right.m1 + left.m9 * right.m5 + left.m10 * right.m9 + left.m11 * right.m13,
                        .m10 = left.m8 * right.m2 + left.m9 * right.m6 + left.m10 * right.m10 + left.m11 * right.m14,
                        .m11 = left.m8 * right.m3 + left.m9 * right.m7 + left.m10 * right.m11 + left.m11 * right.m15,
                        .m12 = left.m12 * right.m0 + left.m13 * right.m4 + left.m14 * right.m8 + left.m15 * right.m12,
                        .m13 = left.m12 * right.m1 + left.m13 * right.m5 + left.m14 * right.m9 + left.m15 * right.m13,
                        .m14 = left.m12 * right.m2 + left.m13 * right.m6 + left.m14 * right.m10 + left.m15 * right.m14,
                        .m15 = left.m12 * right.m3 + left.m13 * right.m7 + left.m14 * right.m11 + left.m15 * right.m15,
                    };
                }

                /// Returns an translation matrix
                pub fn translate(x: T, y: T, z: T) Self {
                    return Self{
                        .m0 = 1,
                        .m4 = 0,
                        .m8 = 0,
                        .m12 = x,
                        .m1 = 0,
                        .m5 = 1,
                        .m9 = 0,
                        .m13 = y,
                        .m2 = 0,
                        .m6 = 0,
                        .m10 = 1,
                        .m14 = z,
                        .m3 = 0,
                        .m7 = 0,
                        .m11 = 0,
                        .m15 = 1,
                    };
                }

                /// Returns an scaled matrix
                pub fn scale(x: T, y: T, z: T) Self {
                    return Self{
                        .m0 = x,
                        .m4 = 0,
                        .m8 = 0,
                        .m12 = 0,
                        .m1 = 0,
                        .m5 = y,
                        .m9 = 0,
                        .m13 = 0,
                        .m2 = 0,
                        .m6 = 0,
                        .m10 = z,
                        .m14 = 0,
                        .m3 = 0,
                        .m7 = 0,
                        .m11 = 0,
                        .m15 = 1,
                    };
                }

                /// Invert provided matrix
                pub fn invert(self: Self) Self {
                    // Cache the matrix values (speed optimization)
                    const a00 = self.m0;
                    const a01 = self.m1;
                    const a02 = self.m2;
                    const a03 = self.m3;
                    const a10 = self.m4;
                    const a11 = self.m5;
                    const a12 = self.m6;
                    const a13 = self.m7;
                    const a20 = self.m8;
                    const a21 = self.m9;
                    const a22 = self.m10;
                    const a23 = self.m11;
                    const a30 = self.m12;
                    const a31 = self.m13;
                    const a32 = self.m14;
                    const a33 = self.m15;

                    const b00 = a00 * a11 - a01 * a10;
                    const b01 = a00 * a12 - a02 * a10;
                    const b02 = a00 * a13 - a03 * a10;
                    const b03 = a01 * a12 - a02 * a11;
                    const b04 = a01 * a13 - a03 * a11;
                    const b05 = a02 * a13 - a03 * a12;
                    const b06 = a20 * a31 - a21 * a30;
                    const b07 = a20 * a32 - a22 * a30;
                    const b08 = a20 * a33 - a23 * a30;
                    const b09 = a21 * a32 - a22 * a31;
                    const b10 = a21 * a33 - a23 * a31;
                    const b11 = a22 * a33 - a23 * a32;

                    // Calculate the invert determinant (inlined to avoid double-caching)
                    const invDet: T = 1 / (b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06);
                    return Self{
                        .m0 = (a11 * b11 - a12 * b10 + a13 * b09) * invDet,
                        .m1 = (-a01 * b11 + a02 * b10 - a03 * b09) * invDet,
                        .m2 = (a31 * b05 - a32 * b04 + a33 * b03) * invDet,
                        .m3 = (-a21 * b05 + a22 * b04 - a23 * b03) * invDet,

                        .m4 = (-a10 * b11 + a12 * b08 - a13 * b07) * invDet,
                        .m5 = (a00 * b11 - a02 * b08 + a03 * b07) * invDet,
                        .m6 = (-a30 * b05 + a32 * b02 - a33 * b01) * invDet,
                        .m7 = (a20 * b05 - a22 * b02 + a23 * b01) * invDet,

                        .m8 = (a10 * b10 - a11 * b08 + a13 * b06) * invDet,
                        .m9 = (-a00 * b10 + a01 * b08 - a03 * b06) * invDet,
                        .m10 = (a30 * b04 - a31 * b02 + a33 * b00) * invDet,
                        .m11 = (-a20 * b04 + a21 * b02 - a23 * b00) * invDet,

                        .m12 = (-a10 * b09 + a11 * b07 - a12 * b06) * invDet,
                        .m13 = (a00 * b09 - a01 * b07 + a02 * b06) * invDet,
                        .m14 = (-a30 * b03 + a31 * b01 - a32 * b00) * invDet,
                        .m15 = (a20 * b03 - a21 * b01 + a22 * b00) * invDet,
                    };
                }

                /// Returns perspective projection matrix
                pub fn frustum(left: T, right: T, bottom: T, top: T, near: T, far: T) Self {
                    const rl = right - left;
                    const tb = top - bottom;
                    const _fn = far - near;

                    return Self{
                        .m0 = (near * 2) / rl,
                        .m1 = 0,
                        .m2 = 0,
                        .m3 = 0,

                        .m4 = 0,
                        .m5 = (near * 2) / tb,
                        .m6 = 0,
                        .m7 = 0,

                        .m8 = (right + left) / rl,
                        .m9 = (top + bottom) / tb,
                        .m10 = -(far + near) / _fn,
                        .m11 = -1,

                        .m12 = 0,
                        .m13 = 0,
                        .m14 = -(far * near * 2) / _fn,
                        .m15 = 0,
                    };
                }

                /// Returns perspective projection matrix
                /// NOTE: Angle should be provided in radians
                pub fn perspective(fovy: T, aspect: T, near: T, far: T) Self {
                    const top = near * tan(fovy * 0.5);
                    const right = top * aspect;
                    return Self.frustum(-right, right, -top, top, near, far);
                }

                /// Returns orthographic projection matrix
                pub fn ortho(left: T, right: T, bottom: T, top: T, near: T, far: T) Self {
                    const rl = right - left;
                    const tb = top - bottom;
                    const _fn = far - near;

                    return .{
                        .m0 = 2 / rl,
                        .m1 = 0,
                        .m2 = 0,
                        .m3 = 0,
                        .m4 = 0,
                        .m5 = 2 / tb,
                        .m6 = 0,
                        .m7 = 0,
                        .m8 = 0,
                        .m9 = 0,
                        .m10 = -2 / _fn,
                        .m11 = 0,
                        .m12 = -(left + right) / rl,
                        .m13 = -(top + bottom) / tb,
                        .m14 = -(far + near) / _fn,
                        .m15 = 1,
                    };
                }

                /// Create rotation matrix from axis and angle
                /// NOTE: Angle should be provided in radians
                pub fn rotate(x0: T, y0: T, z0: T, angle: T) Self {
                    var x = x0;
                    var y = y0;
                    var z = z0;

                    var len = sqrt(x * x + y * y + z * z);
                    if ((len != 1) and (len != 0)) {
                        len = 1 / len;
                        x *= len;
                        y *= len;
                        z *= len;
                    }
                    const sinres = sin(angle);
                    const cosres = cos(angle);
                    const t = 1.0 - cosres;

                    return Self{
                        .m0 = x * x * t + cosres,
                        .m1 = y * x * t + z * sinres,
                        .m2 = z * x * t - y * sinres,
                        .m3 = 0,

                        .m4 = x * y * t - z * sinres,
                        .m5 = y * y * t + cosres,
                        .m6 = z * y * t + x * sinres,
                        .m7 = 0,

                        .m8 = x * z * t + y * sinres,
                        .m9 = y * z * t - x * sinres,
                        .m10 = z * z * t + cosres,
                        .m11 = 0,

                        .m12 = 0,
                        .m13 = 0,
                        .m14 = 0,
                        .m15 = 1,
                    };
                }

                /// Converts the matrix into the array(column major)
                pub fn toArray(self: Self) [16]T {
                    return [16]T{
                        self.m0,
                        self.m1,
                        self.m2,
                        self.m3,

                        self.m4,
                        self.m5,
                        self.m6,
                        self.m7,

                        self.m8,
                        self.m9,
                        self.m10,
                        self.m11,

                        self.m12,
                        self.m13,
                        self.m14,
                        self.m15,
                    };
                }
            };
        },
        else => @compileError("Matrix4x4 not implemented for " ++ @typeName(T)),
    }
}
