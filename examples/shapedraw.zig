const std = @import("std");
const engine = @import("kiragine");

const windowWidth = 1024;
const windowHeight = 768;
const title = "Shapes";
const targetfps = 60;

fn draw() !void {
    engine.clearScreen(0.1, 0.1, 0.1, 1.0);

    // Push the pixel batch, it can't be mixed with any other
    try engine.pushBatch2D(engine.Renderer2DBatchTag.pixels);
    // Draw pixels
    var i: u32 = 0;
    while (i < 10) : (i += 1) {
        try engine.drawPixel(.{ .x = 630 + @intToFloat(f32, i), .y = 100 + @intToFloat(f32, i * i) }, engine.Colour.rgba(240, 30, 30, 255));
        try engine.drawPixel(.{ .x = 630 - @intToFloat(f32, i), .y = 100 + @intToFloat(f32, i * i) }, engine.Colour.rgba(240, 240, 240, 255));
    }
    // Pops the current batch
    try engine.popBatch2D();

    // Push the line batch, it can't be mixed with any other
    try engine.pushBatch2D(engine.Renderer2DBatchTag.lines);
    // Draw line
    try engine.drawLine(.{ .x = 400, .y = 400 }, .{ .x = 400, .y = 500 }, engine.Colour.rgba(255, 255, 255, 255));
    // Pops the current batch
    try engine.popBatch2D();

    // Push the triangle batch, it can be mixed with quad batch
    try engine.pushBatch2D(engine.Renderer2DBatchTag.triangles);
    // or
    // try engine.pushBatch2D(engine.Renderer2DBatchTag.quads);

    const triangle = [3]engine.Vec2f{
        .{ .x = 100, .y = 100 },
        .{ .x = 125, .y = 75 },
        .{ .x = 150, .y = 100 },
    };
    // Draw triangle
    try engine.drawTriangle(triangle[0], triangle[1], triangle[2], engine.Colour.rgba(70, 200, 30, 255));
    // Draw rectangle
    try engine.drawRectangle(.{ .x = 300, .y = 300, .width = 32, .height = 32 }, engine.Colour.rgba(200, 70, 30, 255));

    // Draw rectangle rotated
    const origin = engine.Vec2f{ .x = 16, .y = 16 };
    const rot = engine.kira.math.deg2radf(45);
    try engine.drawRectangleRotated(.{ .x = 500, .y = 300, .width = 32, .height = 32 }, origin, rot, engine.Colour.rgba(30, 70, 200, 255));

    // Draws a circle
    try engine.drawCircle(.{ .x = 700, .y = 500 }, 30, engine.Colour.rgba(200, 200, 200, 255));

    // Pops the current batch
    try engine.popBatch2D();
}

pub fn main() !void {
    try engine.init(null, null, draw, windowWidth, windowHeight, title, targetfps, std.heap.page_allocator);

    try engine.open();
    try engine.update();

    try engine.deinit();
}
