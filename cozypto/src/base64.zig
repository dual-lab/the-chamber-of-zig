const std = @import("std");
const math = std.math;

pub const Base64 = struct {
    _table: *const [64]u8,

    const Self = @This();
    const noop = '=';

    pub fn init() Self {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const num_symb = "0123456789+/";
        return .{
            ._table = upper ++ lower ++ num_symb,
        };
    }

    pub fn encode(
        self: Self,
        allocator: std.mem.Allocator,
        input: []const u8,
    ) ![]const u8 {
        if (input.len == 0) {
            return "";
        }

        const n_out = try calcEncodeLen(input);
        var out = try allocator.alloc(u8, n_out);
        @memset(out, 0);

        var count: u8 = 0;
        var buf = [_]u8{0} ** 3;
        var iout: u64 = 0;

        for (input) |value| {
            buf[count] = value;
            count += 1;
            if (count == 3) {
                out[iout] = self.charAt(buf[0] >> 2);
                out[iout + 1] = self
                    .charAt(((buf[0] & 0x03) << 4) + (buf[1] >> 4));
                out[iout + 2] = self
                    .charAt(((buf[1] & 0x0f) << 2) + (buf[2] >> 6));
                out[iout + 3] = self.charAt(buf[2] & 0x3f);

                iout += 4;
                count = 0;
            }
        }

        if (count == 1) {
            out[iout] = self.charAt(buf[0] >> 2);
            out[iout + 1] = self.charAt((buf[0] & 0x03) << 4);
            out[iout + 2] = noop;
            out[iout + 3] = noop;
        } else if (count == 2) {
            out[iout] = self.charAt(buf[0] >> 2);
            out[iout + 1] = self
                .charAt(((buf[0] & 0x03) << 4) + (buf[1] >> 4));
            out[iout + 2] = self
                .charAt(((buf[1] & 0x0f) << 2));
            out[iout + 3] = noop;
        }

        return out;
    }

    pub fn decode(
        self: Self,
        allocator: std.mem.Allocator,
        input: []const u8,
    ) ![]const u8 {
        if (input.len == 0) {
            return "";
        }

        const n_out = try calcDecoderLen(input);
        const out = try allocator.alloc(u8, n_out);
        @memset(out, 0);

        var count: u8 = 0;
        var iout: u64 = 0;
        var buf = [_]u8{0} ** 4;

        for (input) |value| {
            buf[count] = self.indexAt(value);
            count += 1;
            if (count == 4) {
                out[iout] = (buf[0] << 2) + (buf[1] >> 4);
                if (buf[2] != 64) {
                    out[iout + 1] = (buf[1] << 4) + (buf[2] >> 2);
                }
                if (buf[3] != 64) {
                    out[iout + 2] = (buf[2] << 6) + buf[3];
                }
                iout += 3;
                count = 0;
            }
        }

        return out;
    }

    fn charAt(self: Self, index: usize) u8 {
        return self._table[index];
    }

    fn indexAt(_: Self, char: u8) u8 {
        return switch (char) {
            65...90 => char - 65,
            97...122 => char - 71,
            48...57 => char + 4,
            43 => char + 19,
            47 => char + 16,
            else => 64,
        };
    }

    fn calcEncodeLen(input: []const u8) !usize {
        if (input.len < 3) {
            return @as(usize, 4);
        }

        const n_out = try math.divCeil(usize, input.len, 3);
        return n_out * 4;
    }

    fn calcDecoderLen(input: []const u8) !usize {
        const noop_pos = std.mem.indexOf(u8, input, "=") orelse input.len;
        if (input.len < 4) {
            return @as(usize, 3);
        }

        const n_out = try math.divFloor(usize, input.len, 4);
        return n_out * 3 - (input.len - noop_pos);
    }
};

test "Return empty string if encdoding an empty string" {
    const b64 = Base64.init();

    const allocator = std.testing.allocator;
    const encoded = try b64.encode(allocator, "");
    defer allocator.free(encoded);

    try std.testing.expectEqualStrings("", encoded);
}

test "Return empty string if decoding empty string" {
    const b64 = Base64.init();

    const allocator = std.testing.allocator;
    const decoded = try b64.decode(allocator, "");
    defer allocator.free(decoded);

    try std.testing.expectEqualStrings("", decoded);
}

test "Correct encode in base64" {
    const b64 = Base64.init();

    const allocator = std.testing.allocator;
    const encoded = try b64.encode(allocator, "i'm base64 encoded!");
    defer allocator.free(encoded);

    try std.testing.expectEqualStrings("aSdtIGJhc2U2NCBlbmNvZGVkIQ==", encoded);
}

test "Correct decode in base64" {
    const b64 = Base64.init();

    const allocator = std.testing.allocator;
    const decoded = try b64.decode(allocator, "aSdtIGJhc2U2NCBlbmNvZGVkIQ==");
    defer allocator.free(decoded);

    try std.testing.expectEqualStrings("i'm base64 encoded!", decoded);
}
