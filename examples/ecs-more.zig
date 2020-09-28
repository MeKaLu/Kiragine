const engine = @import("kiragine");

const ecs = engine.ecs;
const seed = 0;

const std = @import("std");
usingnamespace @import("kiragine").kira.log;

const ComponentList = ecs.Components(seed, "kira-");

const max_entity = 1024;
const Entity = ecs.EntityGeneric(ComponentList);
const System = ecs.SystemGeneric(Entity);

const systemDrawRectComps = [_]u64{
    ComponentList.Alive.tag,
    ComponentList.Transform.tag,
};

fn draw() !void {
    engine.clearScreen(0.1, 0.1, 0.1, 1.0);

    try engine.pushBatch2D(engine.Renderer2DBatchTag.quads);

    if (system.requireFilters(systemDrawRectComps.len, systemDrawRectComps))
        try ecs.Logics.drawRectangle(System, &system, ComponentList.Transform, ComponentList.Alive);

    try engine.popBatch2D();
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

var alloc = std.heap.page_allocator;
var system: System = undefined;

pub fn main() !void {
    const callbacks = engine.Callbacks{
        .draw = draw,
    };
    try engine.init(callbacks, 1024, 768, "ECS", 0, alloc);

    try system.init(alloc);
    defer system.deinit();

    {
        var entity = try alloc.create(Entity);
        try entity.init(alloc);
        const tr = ComponentList.Transform{
            .position = .{ .x = 300, .y = 300 },
            .size = .{ .x = 32, .y = 32 },
            .rotation = 45,
            .colour = engine.Colour.rgba(30, 70, 220, 255),
            .origin = .{ .x = 16, .y = 16 },
        };
        try entity.addComponent(ComponentList.Transform, "transform", tr, ComponentList.Transform.tag);
        try entity.addComponent(ComponentList.Alive, "is_alive", .{ .is_it = true }, ComponentList.Alive.tag);
        try system.addEntity(entity);
    }

    try system.addFilters(systemDrawRectComps.len, systemDrawRectComps);
    try system.updateFilters(systemDrawRectComps.len);

    try engine.open();
    try engine.update();

    try systemDeinit(&system);

    try engine.deinit();
}
