pub fn main() !void {
    // TODO create a cli application
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    const base64 = lib.Base64.init();
    var buffer: [100]u8 = .{0} ** 100;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const eout = try base64.encode(allocator, "HI");
    defer allocator.free(eout);

    const dout = try base64.decode(allocator, eout);
    defer allocator.free(dout);
    std.debug.print("encode Base64 is {s} \n", .{eout});
    std.debug.print("decode Base64 is {s} \n", .{dout});
}

const std = @import("std");
const lib = @import("zigypto");
