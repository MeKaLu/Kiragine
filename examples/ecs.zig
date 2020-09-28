const std = @import("std");
usingnamespace @import("kiragine").kira.log;
const engine = @import("kiragine");

const ComponentList = struct {
    rect: engine.Rectangle = undefined,
    motion: engine.Vec2f = undefined,
    is_alive: bool = false,
};

const ComponentTags = enum {
    rectangle,
    motion,
    isAlive,
};

const MaxObjectTag = 3;
const MaxObject = 1024 * 5;
const MaxFilter = 10;
const Object = engine.ecs.ObjectGeneric(MaxObjectTag, ComponentList);
const World = engine.ecs.WorldGeneric(MaxObject, MaxFilter, Object);

var alloc = std.heap.page_allocator;
var world = World{};

pub fn main() !void {
    const callbacks = engine.Callbacks{
        .draw = draw,
        .fixed = fupdate,
    };
    try engine.init(callbacks, 1024, 768, "ECS", 0, alloc);
    
    world.clearObjects();
    world.clearFilters();
    try world.addFilter(@enumToInt(ComponentTags.rectangle));
    try world.addFilter(@enumToInt(ComponentTags.motion));
    try world.addFilter(@enumToInt(ComponentTags.isAlive));

    var i: u64 = 0;
    while (i < MaxObject) : (i += 1) {
        var object = Object{.id = i};
        object.clearTags();
        object.components = .{
            .rect = .{.x = @intToFloat(f32, i * i), .y = 200, .width = 30, .height = 32},
            .motion = .{.x = 0, .y = 150},
            .is_alive = true,
        };
        
        try object.addTags([MaxObjectTag]u64{@enumToInt(ComponentTags.isAlive), @enumToInt(ComponentTags.motion), @enumToInt(ComponentTags.rectangle)});
        try world.addObject(object);
    }

    world.filterObjects() catch |err| {
        if (err != engine.Error.FailedToAdd) return err;
    };

    try engine.open();
    try engine.update();
    
    try engine.deinit();
}

fn fupdate(fdt: f32) !void {
    if (world.hasFilters(3, [3]u64{@enumToInt(ComponentTags.isAlive), @enumToInt(ComponentTags.motion), @enumToInt(ComponentTags.rectangle)}))
        try systemMotion(&world, fdt);
}

fn draw() !void {
    engine.clearScreen(0.1, 0.1, 0.1, 1.0);

    try engine.pushBatch2D(engine.Renderer2DBatchTag.quads);

    if (world.hasFilters(2, [2]u64{@enumToInt(ComponentTags.isAlive), @enumToInt(ComponentTags.rectangle)}))
        try systemDrawRectangle(&world);
    
    try engine.popBatch2D();
}

fn systemMotion(self: *World, fdt: f32) engine.Error!void {
    var i: u64 = 0;
    while (i < self.filteredidlist.count) : (i += 1) {
        if (!self.filteredidlist.items[i].is_exists) continue;

        var ent = self.filteredlist[i];
        const is_alive = try ent.getComponent(bool, "is_alive", @enumToInt(ComponentTags.isAlive));
        if (is_alive) {
            const motion = try ent.getComponent(engine.Vec2f, "motion", @enumToInt(ComponentTags.motion));
            var rect = try ent.getComponent(engine.Rectangle, "rect", @enumToInt(ComponentTags.rectangle));
            rect.x += motion.x * fdt;
            rect.y += motion.y * fdt;
            if (rect.y > 768) rect.y = 0;
            try ent.replaceComponent(engine.Rectangle, "rect", rect, @enumToInt(ComponentTags.rectangle));
        }
    }
}

fn systemDrawRectangle(self: *World) engine.Error!void {
    var i: u64 = 0;
    while (i < self.filteredidlist.count) : (i += 1) {
        if (!self.filteredidlist.items[i].is_exists) continue;

        const ent = self.filteredlist[i];
        const is_alive = try ent.getComponent(bool, "is_alive", @enumToInt(ComponentTags.isAlive));
        if (is_alive) {
            const rect = try ent.getComponent(engine.Rectangle, "rect", @enumToInt(ComponentTags.rectangle));
            try engine.drawRectangle(rect, .{.r = 1, .g = 1, .b = 1, .a = 1});
        }
    }
}