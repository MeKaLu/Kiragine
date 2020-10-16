const std = @import("std");
const kira = @import("kira");
const check = kira.utils.check;
usingnamespace kira.log;

const clap = @import("zig-clap/clap.zig");

const fallback_output = "testbuf";
const fallback_actual_output = "actual-testbuf";

pub fn main() !void {
    // First we specify what parameters our program can take.
    const params = [_]clap.Param(u8){
        clap.Param(u8){
            .id = 'f',
            .takes_value = .One,
        },
        clap.Param(u8){
            .id = 'h',
            .names = clap.Names{ .short = 'h', .long = "help" },
            .takes_value = .None,
        },
        clap.Param(u8){
            .id = 'o',
            .names = clap.Names{ .short = 'o', .long = "output" },
            .takes_value = .One,
        },
        clap.Param(u8){
            .id = 'a',
            .names = clap.Names{ .short = 'a', .long = "actual-output" },
            .takes_value = .One,
        },
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = &gpa.allocator;
    var file: std.fs.File = undefined;
    var output: ?[]const u8 = null;
    var actual_output: ?[]const u8 = null;
    var elements = std.ArrayList(kira.utils.DataPacker.Element).init(alloc);

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
                'h' => {
                    std.debug.print("************ Asset packer help section *************\n", .{});
                    std.debug.print("-h, --help                    Display this help and exit.\n", .{});
                    std.debug.print("-o, --output                  Name of the data file.\n", .{});
                    std.debug.print("-a, --actual_output           Name of the data locations file.\n", .{});
                    std.debug.print("<source-file>                 Path to a source file(can up to as many as you want).\n", .{});
                    std.debug.print("****************************************************\n", .{});
                },
                'o' => {
                    if (arg.value) |val| {
                        output.? = val;
                    } else {
                        output = fallback_output;
                        std.log.scoped(.assetpacker).err("Output file not found! Fallback to using '{}'!", .{output.?});
                    }
                },
                'a' => {
                    if (arg.value) |val| {
                        actual_output.? = val;
                    } else {
                        actual_output = fallback_actual_output;
                        std.log.scoped(.assetpacker).err("Actual output file not found! Fallback to using '{}'!", .{actual_output.?});
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
                    try elements.append(res);
                    alloc.free(data);
                },
                else => unreachable,
            }
        }

        if (elements.items.len == 0) {
            std.log.scoped(.assetpacker).emerg("Please specify atleast one source file. For more information use -h or --help flag.", .{});
            return;
        }

        if (output == null) {
            output = fallback_output;
            std.log.scoped(.assetpacker).err("Output file not found! Fallback to using '{}'!", .{output.?});
        }

        if (actual_output == null) {
            actual_output = fallback_actual_output;
            std.log.scoped(.assetpacker).err("Actual output file not found! Fallback to using '{}'!", .{actual_output.?});
        }

        std.log.scoped(.assetpacker).info("Writing the data into '{}'!", .{output.?});

        file = try std.fs.cwd().createFile(output.?, .{});
        try file.writeAll(packer.buffer[0..packer.stack]);
        file.close();

        std.log.scoped(.assetpacker).info("Writing the data locations into '{}'!", .{actual_output.?});
        {
            file = try std.fs.cwd().createFile(actual_output.?, .{});
            defer file.close();
            var i: u32 = 0;

            // Format the data
            while (i < elements.items.len) : (i += 1) {
                const data = elements.items[i];
                // <id> <start position> <end position>
                const buf = try std.fmt.allocPrint(alloc, "{} {} {}\n", .{ i, data.start, data.end });
                try file.writeAll(buf);
                alloc.free(buf);
            }
        }
        elements.deinit();
    }
    std.log.scoped(.assetpacker).info("Done.", .{});

    try check(gpa.deinit() == true, "Leak found!", .{});
}
