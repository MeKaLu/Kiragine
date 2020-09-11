const std = @import("std");
const engine = @import("kiragine");

const maxparticle = 1000;
const ParticleSystem = engine.ParticleSystemGeneric(maxparticle);

const windowWidth = 1024;
const windowHeight = 768;
const title = "Particle system";
const targetfps = 60;

var rand: std.rand.Xoroshiro128 = undefined;

var particlesys = ParticleSystem{ .drawfn = particledraw };

fn particledraw(self: engine.Particle) engine.Error!void {
    const rect = engine.Rectangle{
        .x = self.position.x,
        .y = self.position.y,
        .width = self.size.x,
        .height = self.size.y,
    };
    try engine.drawRectangle(rect, self.colour);
}

fn fixedUpdate(fixedtime: f32) !void {
    particlesys.update(fixedtime);

    var i: u32 = 0;
    while (i < 10) : (i += 1) {
        const rann = rand.random.intRangeLessThan(i32, -100, 100);
        const p = engine.Particle{
            .position = .{ .x = 300 + @intToFloat(f32, i * i), .y = windowHeight - 100 },
            .size = .{ .x = 5, .y = 5 },
            .velocity = .{ .x = @intToFloat(f32, rann), .y = -100 },
            .lifetime = 1.75,
            .colour = engine.Colour.rgba(70, 200, 30, 255),
        };
        _ = particlesys.add(p);
    }
}

fn draw() !void {
    engine.clearScreen(0.1, 0.1, 0.1, 1.0);

    // Push the triangle batch, it can be mixed with quad batch
    try engine.pushBatch2D(engine.Renderer2DBatchTag.triangles);

    if (!(try particlesys.draw())) {
        try engine.printEndl(engine.LogLevel.warn, "Particle system has failed to draw", .{});
    }

    // Pops the current batch
    try engine.popBatch2D();
}

pub fn main() !void {
    try engine.init(null, fixedUpdate, draw, windowWidth, windowHeight, title, targetfps, std.heap.page_allocator);

    var buf: [8]u8 = undefined;
    try std.crypto.randomBytes(buf[0..]);
    const seed = std.mem.readIntLittle(u64, buf[0..8]);
    var r = std.rand.DefaultPrng.init(seed);

    rand = r.random;

    try engine.open();
    try engine.update();

    try engine.deinit();
}
