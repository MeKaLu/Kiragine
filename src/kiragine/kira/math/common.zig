// -----------------------------------------
// |           Kiragine 1.0.1              |
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

const assert = @import("std").debug.assert;
pub const PI = comptime 3.14159265358979323846;

/// Convert degree to radians
pub fn deg2radf(deg: f32) f32 {
    return deg * (PI / 180.0);
}
/// Convert radians to degree
pub fn rad2degf(rad: f32) f32 {
    return rad * (180.0 / PI);
}
/// Find minimum value
pub fn min(value1: anytype, value2: anytype) @TypeOf(value1) {
    return if (value1 < value2) value1 else value2;
}
/// Find maximum value
pub fn max(value1: anytype, value2: anytype) @TypeOf(value1) {
    return if (value1 < value2) value2 else value1;
}
/// Clamp value
pub fn clamp(value: anytype, low: anytype, high: anytype) @TypeOf(value) {
    assert(low <= high);
    return if (value < low) low else if (high < value) high else value;
}
/// Calculate linear interpolation between two value
pub fn lerp(start: anytype, end: anytype, amount: anytype) @TypeOf(start) {
    return start + amount * (end - start);
}
/// Normalize input value within input range
pub fn normalize(value: anytype, start: anytype, end: anytype) @TypeOf(value) {
    return (value - start) / (end - start);
}
/// Remap input value within input range to output range
pub fn remap(value: anytype, inputStart: anytype, inputEnd: anytype, outputStart: anytype, outputEnd: anytype) @TypeOf(value) {
    return (value - inputStart) / (inputEnd - inputStart) * (outputEnd - outputStart) + outputStart;
}
/// Returns the absolute value
pub fn abs(value: anytype) @TypeOf(value) {
    return if (value >= 0) value else -value;
}
/// AABB collision check
pub fn aabb(x0: anytype, y0: anytype, w0: anytype, h0: anytype, x1: anytype, y2: anytype, w2: anytype, h2: anytype) bool {
    return if (x0 < x1 + w1 and
        x1 < x0 + w0 and
        y0 > y1 + h1 and
        y1 > y0 + h0) true else false;
}
