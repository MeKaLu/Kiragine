const std = @import("std");
const engine = @import("kiragine");

const windowWidth = 1024;
const windowHeight = 768;
const title = "Textures";
const targetfps = 60;

var texture: engine.Texture = undefined;
var textureGenerated: engine.Texture = undefined;

const rect: engine.Rectangle = .{ .x = 500, .y = 380, .width = 32 * 3, .height = 32 * 3 };
const rect2: engine.Rectangle = .{ .x = 300, .y = 400, .width = 32 * 6, .height = 32 * 6 };
const srcrect: engine.Rectangle = .{ .x = 0, .y = 0, .width = 32, .height = 32 };

fn draw() !void {
    engine.clearScreen(0.1, 0.1, 0.1, 1.0);

    // Enable the texture batch with given texture
    engine.enableTextureBatch2D(texture);
    // Push the quad batch, it can't be mixed with any other 'cuz it's textured
    try engine.pushBatch2D(engine.Renderer2DBatchTag.quads);

    // Draw texture rotated
    try engine.drawTextureRotated(rect2, srcrect, .{ .x = 16, .y = 16 }, engine.kira.math.deg2radf(45), engine.Colour.rgba(255, 0, 0, 255));

    // Draw texture
    try engine.drawTexture(rect, srcrect, engine.Colour.rgba(255, 255, 255, 255));

    // Pops the current batch
    try engine.popBatch2D();
    // Disable the texture batch
    engine.disableTextureBatch2D();
}

pub fn main() !void {
    try engine.init(null, null, draw, windowWidth, windowHeight, title, targetfps, std.heap.page_allocator);

    const t = @embedFile("../assets/test.png");
    texture = try engine.Texture.createFromPNGMemory(t);
    // or load it from file
    // texture = try engine.Texture.createFromPNG(filepath);

    try engine.open();
    try engine.update();

    // Destroy the created texture
    texture.destroy();
    try engine.deinit();
}
