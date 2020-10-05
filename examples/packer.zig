const std = @import("std");
const engine = @import("kiragine");
usingnamespace engine.kira.log;

const windowWidth = 1024;
const windowHeight = 768;
const title = "Packer";
const targetfps = 60;

var texture: engine.Texture = undefined;

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
    const callbacks = engine.Callbacks{
        .draw = draw,
    };
    try engine.init(callbacks, windowWidth, windowHeight, title, targetfps, std.heap.page_allocator);

    var file: std.fs.File = undefined;

    var test0png = engine.kira.utils.DataPacker.Element{};
    var test1png = engine.kira.utils.DataPacker.Element{};
    // Pack the data into a file
    {
        var packer = try engine.kira.utils.DataPacker.init(std.heap.page_allocator, 1024);
        defer packer.deinit();
        {
            file = try std.fs.cwd().openFile("assets/test.png", .{});
            const testpnglen = try file.getEndPos();
            const stream = file.reader();
            const testpng = try stream.readAllAlloc(std.heap.page_allocator, testpnglen);
            file.close();
            test0png = try packer.append(testpng);
            std.heap.page_allocator.free(testpng);
        }

        {
            file = try std.fs.cwd().openFile("assets/test2.png", .{});
            const testpng2len = try file.getEndPos();
            const stream = file.reader();
            const testpng2 = try stream.readAllAlloc(std.heap.page_allocator, testpng2len);
            test1png = try packer.append(testpng2);
            file.close();

            std.heap.page_allocator.free(testpng2);
        }

        file = try std.fs.cwd().createFile("testbuf", .{});
        try file.writeAll(packer.buffer[0..packer.stack]);
        file.close();
    }
    // Read the packed data from file
    file = try std.fs.cwd().openFile("testbuf", .{});
    const stream = file.reader();
    const buffer = try stream.readAllAlloc(std.heap.page_allocator, test1png.end);
    file.close();

    texture = try engine.Texture.createFromPNGMemory(buffer[test1png.start..test1png.end]);
    std.heap.page_allocator.free(buffer);

    try engine.open();
    try engine.update();

    texture.destroy();
    try engine.deinit();
}
