const engine = @import("kiragine");

const ecs = engine.ecs;

const hash = std.hash.Wyhash.hash;
const seed = 0;

const std = @import("std");
usingnamespace @import("kiragine").kira.log;

const ComponentList = struct {
    rect: *engine.Rectangle = undefined,
    is_alive: bool = false,
};

const Entity = ecs.EntityGeneric(ComponentList, 10);
const System = ecs.SystemGeneric(10, Entity);

fn fixedupdate(fixed: f32) !void {
    const keyA: engine.Input.State = try input.keyState('A');

    //std.log.debug("FPS: {}", .{engine.getFps()});
}

fn draw() !void {
    engine.clearScreen(0.1, 0.1, 0.1, 1.0);

    try engine.pushBatch2D(engine.Renderer2DBatchTag.quads);

    try engine.popBatch2D();
}

var input: *engine.Input = undefined;
var arenaalloc: std.heap.ArenaAllocator = undefined;
var alloc = &arenaalloc.allocator;

pub fn main() !void {
    arenaalloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arenaalloc.deinit();

    const callbacks = engine.Callbacks{
        .fixed = fixedupdate,
        .draw = draw,
    };
    try engine.init(callbacks, 1024, 768, "ECS", 60, alloc);
    input = engine.getInput();
    try input.bindKey('A');

    var system = System{};
    system.clearFilter();
    const tags = [Entity.max_tags]u64{
        hash(seed, "RectangleComponent"), ecs.invalid,
        hash(seed, "IsAliveComponent"),   ecs.invalid,
        ecs.invalid,                      ecs.invalid,
        ecs.invalid,                      ecs.invalid,
        ecs.invalid,                      ecs.invalid,
    };

    var entity = Entity{
        .id = hash(seed, "basic"),
    };
    entity.clearTags();

    var rect = engine.Rectangle{};
    try entity.addComponentPtr(engine.Rectangle, "rect", &rect, hash(seed, "RectangleComponent"));
    try entity.addComponent(bool, "is_alive", true, hash(seed, "IsAliveComponent"));
    try system.addEntity(entity);

    try system.filter(tags);
    std.log.debug("{}", .{system.filtered_list[0]});

    try engine.open();
    try engine.update();

    try engine.deinit();
}
