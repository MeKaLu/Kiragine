const std = @import("std");

// This is essantial if you want to use custom logging
// that kiragine provides
usingnamespace @import("kiragine").kira.log;

pub fn main() void {
    std.log.emerg("Emerg !", .{});
    std.log.alert("Alert !", .{});
    std.log.crit("Crit !", .{});
    std.log.err("Err !", .{});
    std.log.warn("Warn !", .{});
    std.log.notice("Notice !", .{});
    std.log.info("Info !", .{});
    std.log.debug("Debug !", .{});
}