const std = @import("std");

const myerrors = error{ err1, err2 };
const myerrors2 = error{ whush2, whush3 };

const merge = myerrors || myerrors2;

fn retutnerr1() myerrors!void {
    return myerrors.err1;
}

fn retutnwhush2() myerrors2!void {
    return myerrors2.whush2;
}

fn handle() !void {
    retutnerr1() catch |err| {
        if (err == merge.err1) {
            std.debug.print("yay 1\n", .{});
        } else return err;
    };
    retutnwhush2() catch |err| {
        if (err == merge.whush2) {
            std.debug.print("yay 2\n", .{});
        } else return err;
    };
}

pub fn main() !void {
    try handle();
}
