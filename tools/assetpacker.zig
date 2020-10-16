const std = @import("std");
const kira = @import("kira");
const check = kira.utils.check;
usingnamespace kira.log;

const clap = @import("zig-clap/clap.zig");

pub fn main() !void {
    // First we specify what parameters our program can take.
    const params = [_]clap.Param(u8){
        clap.Param(u8){
            .id = 'f',
            .takes_value = .One,
        },
        clap.Param(u8){
            .id = 'o',
            .names = clap.Names{ .short = 'o', .long = "output" },
            .takes_value = .One,
        },
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = &gpa.allocator;
    var file: std.fs.File = undefined;
    var output: ?[]const u8 = null;

    // We then initialize an argument iterator. We will use the OsIterator as it nicely
    // wraps iterating over arguments the most efficient way on each os.
    var iter = try clap.args.OsIterator.init(alloc);
    defer iter.deinit();

    // Initialize our streaming parser.
    var parser = clap.StreamingClap(u8, clap.args.OsIterator){
        .params = &params,
        .iter = &iter,
    };

    // Pack the data into a file
    {
        var packer = try kira.utils.DataPacker.init(alloc, 1024);
        defer packer.deinit();

        // Because we use a streaming parser, we have to consume each argument parsed individually.
        while (try parser.next()) |arg| {
            // arg.param will point to the parameter which matched the argument.
            switch (arg.param.id) {
                'o' => {
                    if (arg.value) |val| {
                        output.? = val;
                    } else {
                        output = "testbuf";
                        std.log.scoped(.assetpacker).err("Output file not found! Fallback to using '{}'!", .{output.?});
                    }
                },
                'f' => {
                    std.log.scoped(.assetpacker).info("Reading source: {}", .{arg.value.?});
                    file = try std.fs.cwd().openFile(arg.value.?, .{});
                    const len = try file.getEndPos();
                    const stream = file.reader();
                    const data = try stream.readAllAlloc(alloc, len);
                    file.close();
                    const res = try packer.append(data);
                    alloc.free(data);
                },
                else => unreachable,
            }
        }
        if (output == null) {
            output = "testbuf";
            std.log.scoped(.assetpacker).err("Output file not found! Fallback to using '{}'!", .{output.?});
        }

        std.log.scoped(.assetpacker).info("Writing the data into '{}'!", .{output.?});

        file = try std.fs.cwd().createFile(output.?, .{});
        try file.writeAll(packer.buffer[0..packer.stack]);
        file.close();
    }

    // Read the packed data from file
    //file = try std.fs.cwd().openFile(output.?, .{});
    //const len = try file.getEndPos();
    //const stream = file.reader();
    //const buffer = try stream.readAllAlloc(alloc, len);
    //file.close();
    //alloc.free(buffer);

    try check(gpa.deinit() == true, "Leak found!", .{});
}
