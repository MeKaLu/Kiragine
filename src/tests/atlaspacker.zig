const std = @import("std");
const engine = @import("kiragine");
usingnamespace engine.kira.log;

const gl = engine.kira.gl;
const c = engine.kira.c;

const windowWidth = 1024;
const windowHeight = 768;
const title = "Textures";
const targetfps = 60;

var texture: engine.Texture = undefined;

const rect: engine.Rectangle = .{ .x = 500, .y = 380, .width = 32 * 3, .height = 32 * 3 };
const rect2: engine.Rectangle = .{ .x = 300, .y = 400, .width = 32 * 6, .height = 32 * 6 };
const srcrect: engine.Rectangle = .{ .x = 0, .y = 0, .width = 32, .height = 32 };

fn draw() !void {
    engine.clearScreen(0.1, 0.1, 0.1, 1.0);

    //const texture = engine.Texture{
    //.id = atlas.textureid,
    //};

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

    file = try std.fs.cwd().openFile("assets/test.png", .{});
    const testpnglen = try file.getEndPos();
    const stream = file.reader();
    const testpng = try stream.readAllAlloc(std.heap.page_allocator, testpnglen);
    file.close();
    defer std.heap.page_allocator.free(testpng);

    file = try std.fs.cwd().openFile("assets/test2.png", .{});
    const testpng2len = try file.getEndPos();
    const sstream = file.reader();
    const testpng2 = try sstream.readAllAlloc(std.heap.page_allocator, testpng2len);
    file.close();
    defer std.heap.page_allocator.free(testpng2);

    file = try std.fs.cwd().createFile("testbuf", .{});
    try file.writeAll(testpng);
    try file.writeAll("\n\n");
    try file.writeAll(testpng2);
    file.close();

    file = try std.fs.cwd().openFile("testbuf", .{});
    const testbufferlen = try file.getEndPos();
    const ssstream = file.reader();
    const testbuffer = try ssstream.readAllAlloc(std.heap.page_allocator, testpng2len + testpnglen + 2);
    const mem = testbuffer[testpnglen + 2 ..];
    const mem2 = testbuffer[0..testpnglen];
    file.close();
    defer std.heap.page_allocator.free(testbuffer);

    var nrchannels: i32 = 0;
    var data: ?*u8 = c.stbi_load_from_memory(@ptrCast([*c]const u8, mem2), @intCast(i32, mem2.len), &texture.width, &texture.height, &nrchannels, 4);
    defer c.stbi_image_free(data);

    texture = engine.Texture{
        .id = 0,
        .width = 32,
        .height = 32,
    };
    gl.texturesGen(1, @ptrCast([*]u32, &texture.id));
    gl.textureBind(gl.TextureType.t2D, texture.id);

    gl.textureTexParameteri(gl.TextureType.t2D, gl.TextureParamaterType.min_filter, gl.TextureParamater.filter_nearest);
    gl.textureTexParameteri(gl.TextureType.t2D, gl.TextureParamaterType.mag_filter, gl.TextureParamater.filter_nearest);

    gl.textureTexParameteri(gl.TextureType.t2D, gl.TextureParamaterType.wrap_s, gl.TextureParamater.wrap_repeat);
    gl.textureTexParameteri(gl.TextureType.t2D, gl.TextureParamaterType.wrap_t, gl.TextureParamater.wrap_repeat);

    gl.textureTexImage2D(gl.TextureType.t2D, 0, gl.TextureFormat.rgba8, 32, 32, 0, gl.TextureFormat.rgba, u8, @ptrCast(?*c_void, data));
    gl.textureBind(gl.TextureType.t2D, 0);

    try engine.open();
    try engine.update();

    texture.destroy();
    try engine.deinit();
}
