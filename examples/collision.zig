const std = @import("std");
usingnamespace @import("kiragine").kira.log;
const engine = @import("kiragine");
const kira = engine.kira;

const windowWidth = 1024;
const windowHeight = 768;
const title = "test";
const targetfps = 60;

const callbacks = engine.Callbacks{
    .update = update,
    .fixed = fixedupdate,
    .draw = draw,
};

var cam: *engine.Camera2D = undefined;
var mpos: engine.Vec2f = undefined;

var rect = engine.Rectangle{ .x = 300, .y = 300, .width = 32, .height = 32 };
const aabrect = engine.Rectangle{ .x = 400, .y = 400, .width = 32, .height = 32 };

fn update(dt: f32) !void {
    mpos = cam.worldToScreen(.{ .x = engine.getMouseX(), .y = engine.getMouseY() });

    const originated = rect.getOriginated();
    const originated2 = aabrect.getOriginated();
    const collision = kira.math.aabb(originated.x, originated.y, rect.width, rect.height, originated2.x, originated2.y, aabrect.width, aabrect.height);

    if (collision) {
        std.log.notice("Collision!!!", .{});
    }
}

fn fixedupdate(fdt: f32) !void {
    const pos = engine.Vec2f.moveTowards(.{ .x = rect.x, .y = rect.y }, mpos, 50 * fdt);
    if (pos.distance(mpos) > 50) {
        rect.x = pos.x;
        rect.y = pos.y;
    }
}

fn draw() !void {
    engine.clearScreen(0.1, 0.1, 0.1, 1.0);

    try engine.pushBatch2D(engine.Renderer2DBatchTag.triangles);
    try engine.drawRectangleRotated(rect, rect.getOrigin(), 0, engine.Colour.rgba(30, 70, 200, 255));
    try engine.drawRectangleRotated(aabrect, aabrect.getOrigin(), 0, engine.Colour.rgba(255, 255, 255, 255));
    try engine.popBatch2D();
}

pub fn main() !void {
    try engine.init(callbacks, windowWidth, windowHeight, title, targetfps, std.heap.page_allocator);

    cam = engine.getCamera2D();

    try engine.open();
    try engine.update();

    try engine.deinit();
}
