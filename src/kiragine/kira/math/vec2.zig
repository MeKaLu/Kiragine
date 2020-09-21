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

const atan2 = @import("std").math.atan2;
const sqrt = @import("std").math.sqrt;
const cos = @import("std").math.cos;
const sin = @import("std").math.sin;

usingnamespace @import("common.zig");

/// Generic Vector2 Type
pub fn Generic(comptime T: type) type {
    switch (T) {
        i16, i32, i64, i128, f16, f32, f64, f128 => {
            return struct {
                const Self = @This();
                /// X value
                x: T = 0,
                /// Y value
                y: T = 0,

                /// Adds two Vector2s and returns the result
                pub fn add(self: Self, other: Self) Self {
                    return .{ .x = self.x + other.x, .y = self.y + other.y };
                }

                /// Add values to the self and returns the result
                pub fn addValues(self: Self, x: T, y: T) Self {
                    return .{ .x = self.x + x, .y = self.y + y };
                }

                /// Subtracts two Vector2s and returns the result
                pub fn sub(self: Self, other: Self) Self {
                    return .{ .x = self.x - other.x, .y = self.y - other.y };
                }

                /// Subtract values to the self and returns the result
                pub fn subValues(self: Self, x: T, y: T) Self {
                    return .{ .x = self.x - x, .y = self.y - y };
                }

                /// Divides two Vector2s and returns the result
                pub fn div(self: Self, other: Self) Self {
                    return .{ .x = self.x / other.x, .y = self.y / other.y };
                }

                /// Divide values to the self and returns the result
                pub fn divValues(self: Self, x: T, y: T) Self {
                    return .{ .x = self.x / x, .y = self.y / y };
                }

                /// Multiplies two Vector2s and returns the result
                pub fn mul(self: Self, other: Self) Self {
                    return .{ .x = self.x * other.x, .y = self.y * other.y };
                }

                /// Multiply values to the self and returns the result
                pub fn mulValues(self: Self, x: T, y: T) Self {
                    return .{ .x = self.x * x, .y = self.y * y };
                }

                /// Calculate angle from two Vector2s in X-axis in degrees
                pub fn angle(v1: Self, v2: Self) T {
                    const result: T = atan2(T, v2.y - v1.y, v2.x - v1.x) * @as(T, (180.0 / PI));
                    if (result < 0) return result + 360;
                    return result;
                }

                /// Calculate the toward position
                pub fn moveTowards(v1: Self, v2: Self, speed: T) Self {
                    const ang: T = atan2(T, v2.y - v1.y, v2.x - v1.x);
                    return Self{
                        .x = v1.x + cos(ang) * speed,
                        .y = v1.y + sin(ang) * speed,
                    };
                }

                /// Calculate the distance between two points
                pub fn distance(v1: Self, v2: Self) T {
                    const dx = v1.x - v2.x;
                    const dy = v1.y - v2.y;
                    return sqrt(dx * dx + dy * dy);
                }
            };
        },
        else => @compileError("Vector2 not implemented for " ++ @typeName(T)),
    }
}
