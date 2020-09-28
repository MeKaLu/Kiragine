const engine = @import("kiragine");

const ecs = engine.ecs;

const hash = std.hash.Wyhash.hash;
const seed = 0;

const std = @import("std");
usingnamespace @import("kiragine").kira.log;

const ComponentList = struct {
    rect: engine.Rectangle = undefined,
    colour: engine.Colour = undefined,
    is_alive: bool = false,

    motion: engine.Vec2f = undefined,

    ptr: *u32 = undefined,
};

const max_entity = 1024;
const Entity = ecs.EntityGeneric(ComponentList);
const System = ecs.SystemGeneric(Entity);

fn update(dt: f32) !void {
    if (system.requireFilters(movementSystemTag.len, movementSystemTag))
        try systemMove(&system, dt);
}

fn draw() !void {
    engine.clearScreen(0.1, 0.1, 0.1, 1.0);

    try engine.pushBatch2D(engine.Renderer2DBatchTag.quads);

    if (system.requireFilters(rectangleSystemTag.len, rectangleSystemTag))
        try systemRectangle(&system);

    try engine.popBatch2D();
}

fn systemMove(self: *System, fixedtime: f32) !void {
    var i: u64 = 0;
    while (i < self.filtered_list.count) : (i += 1) {
        if (!self.filtered_list.items[i].is_exists) continue;

        const ent = self.filtered_list.items[i].data;
        const is_alive = try ent.getComponent(bool, "is_alive", hash(seed, "IsAliveComponent"));
        if (is_alive) {
            var rect = try ent.getComponent(engine.Rectangle, "rect", hash(seed, "RectangleComponent"));
            var ptr = try ent.getComponent(*u32, "ptr", hash(seed, "PtrComponent"));
            const motion = try ent.getComponent(engine.Vec2f, "motion", hash(seed, "MotionComponent"));

            rect.x += motion.x * fixedtime;
            rect.y += motion.y * fixedtime;
            ptr.* = @floatToInt(u32, rect.x);

            try ent.replaceComponent(engine.Rectangle, "rect", rect, hash(seed, "RectangleComponent"));
            if (rect.x > 1100) {
                try ent.replaceComponent(bool, "is_alive", false, hash(seed, "IsAliveComponent"));
            }
        }
    }
}

fn systemRectangle(self: *System) !void {
    var i: u64 = 0;
    while (i < self.filtered_list.count) : (i += 1) {
        if (!self.filtered_list.items[i].is_exists) continue;
        const ent = self.filtered_list.items[i].data;

        const is_alive = try ent.getComponent(bool, "is_alive", hash(seed, "IsAliveComponent"));
        if (is_alive) {
            const rect = try ent.getComponent(engine.Rectangle, "rect", hash(seed, "RectangleComponent"));
            const colour = try ent.getComponent(engine.Colour, "colour", hash(seed, "ColourComponent"));
            try engine.drawRectangle(rect, colour);
        }
    }
}

fn systemDeinit(self: *System) !void {
    var i: u64 = 0;
    while (i < self.entities.count) : (i += 1) {
        if (!self.entities.items[i].is_exists) continue;
        const ent = self.entities.items[i].data;
        try self.removeEntity(ent);
        ent.deinit();
        alloc.destroy(ent);
    }
}

const rectangleSystemTag = [_]u64{
    hash(seed, "RectangleComponent"),
    hash(seed, "ColourComponent"),
    hash(seed, "IsAliveComponent"),
};

const movementSystemTag = [_]u64{
    hash(seed, "RectangleComponent"),
    hash(seed, "MotionComponent"),
    hash(seed, "PtrComponent"),
    hash(seed, "IsAliveComponent"),
};

var alloc = std.heap.page_allocator;
var system: System = undefined;

pub fn main() !void {
    const callbacks = engine.Callbacks{
        .fixed = update,
        .draw = draw,
    };
    try engine.init(callbacks, 1024, 768, "ECS", 0, alloc);

    engine.kira.glfw.vsync(false);

    try system.init(alloc);
    defer system.deinit();

    try system.addFilters(rectangleSystemTag.len, rectangleSystemTag);
    try system.addFilter(hash(seed, "MotionComponent"));
    try system.addFilter(hash(seed, "PtrComponent"));
    var a: u32 = 100;
    {
        var i: u32 = 0;
        while (i < max_entity) : (i += 1) {
            var entity = try alloc.create(Entity);
            try entity.init(alloc);
            try entity.addComponent(engine.Rectangle, "rect", .{ .x = 100 + @intToFloat(f32, i), .y = 200, .width = 32, .height = 32 }, hash(seed, "RectangleComponent"));
            try entity.addComponent(engine.Colour, "colour", .{ .r = 1, .g = 1, .b = 1, .a = 1 }, hash(seed, "ColourComponent"));
            try entity.addComponent(engine.Vec2f, "motion", .{ .x = 100 }, hash(seed, "MotionComponent"));
            try entity.addComponent(bool, "is_alive", true, hash(seed, "IsAliveComponent"));
            try entity.addComponent(*u32, "ptr", &a, hash(seed, "PtrComponent"));
            try system.addEntity(entity);
        }
    }
    try system.updateFilters(5);

    try engine.open();
    try engine.update();

    std.log.warn("ptr component: {}", .{a});

    try systemDeinit(&system);

    try engine.deinit();
}