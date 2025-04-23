const std = @import("std");
const lib = @import("cozimg");

const ImgFilterError = error{NoInputImg};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloccator = arena.allocator();

    const args = try std.process.argsAlloc(alloccator);
    defer std.process.argsFree(alloccator, args);

    if (args.len < 2) {
        return ImgFilterError.NoInputImg;
    }

    const img_path = args[1];
    std.debug.print("Img to filter  {s}\n", .{img_path});

    try lib.GrayScale.filter(img_path, alloccator);
}
