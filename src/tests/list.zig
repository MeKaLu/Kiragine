const std = @import("std");
const engine = @import("kiragine");
const utils = engine.kira.utils;
usingnamespace engine.kira.log;

const List = utils.UniqueList(u64);

pub fn main() !void {
    var list = try List.init(std.heap.page_allocator, 10);
    defer list.deinit();

    try list.insert(0, true);
    try list.insert(1, true);

    try utils.check(!list.isExists(2), "ups", .{});
}
