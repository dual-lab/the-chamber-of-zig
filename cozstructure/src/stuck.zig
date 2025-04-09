const std = @import("std");
const Allocaor = std.mem.Allocator;

pub fn Stuck(comptime T: type) type {
    return struct {
        items: []T,
        capacity: usize,
        length: usize,
        allocator: Allocaor,

        const Self = @This();

        pub fn init(allcator: Allocaor, cap: usize) !Self {
            const buf = try allcator.alloc(T, cap);

            return .{
                .items = buf,
                .capacity = cap,
                .length = 0,
                .allocator = allcator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.items);
        }

        pub fn pop(self: *Self) ?T {
            if (self.length == 0) {
                return null;
            }

            const last = self.items[self.length - 1];
            self.items[self.length - 1] = undefined;
            self.length -= 1;

            return last;
        }

        pub fn push(self: *Self, value: T) !void {
            if ((self.length + 1) > self.capacity) {
                const new_buf = try self.allocator.alloc(T, self.capacity * 2);

                @memcpy(new_buf, self.items);
                self.allocator.free(self.items);
                self.items = new_buf;
                self.capacity = self.capacity * 2;
            }

            self.items[self.length] = value;
            self.length += 1;
        }
    };
}

test "Allocate stuck with corretc capacity" {
    const allocator = std.testing.allocator;
    const StuckU8 = Stuck(u8);

    var stuck = try StuckU8.init(allocator, 5);
    defer stuck.deinit();

    try std.testing.expectEqual(5, stuck.capacity);

}

test "Push and Pop element into the stuck in LIFO"{
    const allocator = std.testing.allocator;
    const StruckU8 = Stuck(u8);

    var stuck = try StruckU8.init(allocator, 5);
    defer stuck.deinit();

    try stuck.push(1);
    try stuck.push(2);

    try std.testing.expectEqual(2, stuck.length);

    var last = stuck.pop();
    try std.testing.expectEqual(2, last);

    last = stuck.pop();
    try std.testing.expectEqual(1, last);

    last = stuck.pop();

    const value = last orelse 255;
    try std.testing.expect(value == 255);
}
