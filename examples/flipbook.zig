const std = @import("std");
usingnamespace @import("kiragine").kira.log;
const engine = @import("kiragine");

const windowWidth = 1024;
const windowHeight = 768;
const title = "Textures-Flipbook";
const targetfps = 60;

var flipbook = engine.FlipBook{
    .properties = .{
        .frame_size = .{.x = 16, .y = 19},
        .max_frame_size = .{.x = 16 * 4, .y = 19},
        .frame_increase_size = .{.x = 16, .y = 19},
        .fps = 10,
    },
    .srcrect = &srcrect,
};

const rect: engine.Rectangle = .{ .x = 500, .y = 380, .width = 16 * 4, .height = 19 * 4 };
var srcrect: engine.Rectangle = .{ .x = 0, .y = 0, .width = 16, .height = 19 };
//var srcrect: engine.Rectangle = .{ .x = 0, .y = 0, .width = 16 * 4, .height = 19 };

fn update(dt: f32) !void {
    flipbook.update(dt);
}

fn draw() !void {
    engine.clearScreen(0.1, 0.1, 0.1, 1.0);

    // Push the quad batch, it can't be mixed with any other 'cuz it's textured
    try engine.pushBatch2D(engine.Renderer2DBatchTag.quads);

    // Draw texture
    try engine.drawTexture(rect, srcrect, engine.Colour.rgba(255, 255, 255, 255));

    // Pops the current batch
    try engine.popBatch2D();
}

pub fn main() !void {
    const callbacks = engine.Callbacks{
        .draw = draw,
        .update = update,
    };
    try engine.init(callbacks, windowWidth, windowHeight, title, targetfps, std.heap.page_allocator);

    const t = @embedFile("../assets/flipbook.png");
    var texture = try engine.Texture.createFromPNGMemory(t);
    
    // Enable the texture batch with given texture
    engine.enableTextureBatch2D(texture);

    try engine.open();
    try engine.update();
    
    // Disable the texture batch
    engine.disableTextureBatch2D();

    // Destroy the created texture
    texture.destroy();
    try engine.deinit();
}
