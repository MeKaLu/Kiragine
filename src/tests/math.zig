const utils = @import("kira/utils.zig");
const mat4x4 = @import("kira/math/mat4x4.zig");
const vec3 = @import("kira/math/vec3.zig");
const vec2 = @import("kira/math/vec2.zig");
usingnamespace @import("kira/math/camera.zig");

const Mat4x4f = mat4x4.Generic(f32);
const Vec3f = vec3.Generic(f32);
const Vec2f = vec2.Generic(f32);

pub fn main() anyerror!void {
    try utils.initTimer();
    defer utils.deinitTimer();

    const identity = Mat4x4f.identity();
    const ortho = Mat4x4f.ortho(0, 1024, 768, 0, -1, 1);
    const mvp = Mat4x4f.mul(identity, ortho);
    const v = Vec3f{ .x = 100, .y = 0, .z = 0 };

    var cam = Camera2D{};
    cam.ortho = ortho;
    cam.attach();
    try utils.printEndl(utils.LogLevel.trace, "{}", .{cam.worldToScreen(Vec2f{ .x = 10, .y = 10 })});
    try utils.printEndl(utils.LogLevel.trace, "{}", .{cam.screenToWorld(Vec2f{ .x = 200, .y = 200 })});
    cam.detach();

    try utils.printEndl(utils.LogLevel.trace, "{}", .{mvp});
    try utils.printEndl(utils.LogLevel.trace, "{}", .{Vec3f.transform(v, mvp)});
}
