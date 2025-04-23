const c = @import("c");
const spng = @import("spng");
const std = @import("std");

const ImgFilterError = error{
    CouldNotOpenFile,
    CouldNotCreatePngCtx,
    CouldNotGetImgHeader,
    CouldNotGetOutsize,
    CouldNotDecodeImg,
    CouldNotEncodeImg,
};

pub fn filter(path: []const u8, allocator: std.mem.Allocator) !void {
    const fd = c.fopen(path.ptr, "rb");
    defer {
        if (fd != null) {
            _ = c.fclose(fd);
        }
    }
    if (fd == null) {
        return ImgFilterError.CouldNotOpenFile;
    }

    const ctx = spng.spng_ctx_new(0) orelse return ImgFilterError.CouldNotCreatePngCtx;
    defer spng.spng_ctx_free(ctx);
    _ = spng.spng_set_png_file(ctx, @ptrCast(fd));

    const out_size = try getImgSize(ctx);
    const buffer = try allocator.alloc(u8, out_size);
    defer allocator.free(buffer);
    @memset(buffer, 0);

    var img_header = try getImgHeader(ctx);

    try readImg(ctx, buffer);
    try applyFilter(buffer);

    const filtred_path = try std.mem.concat(allocator, u8, &[_][] const u8{ std.fs.path.basename(path), "_grayscale.png" });
    defer allocator.free(filtred_path);
    try saveFiltedImg(filtred_path, &img_header, buffer);
}

fn saveFiltedImg(path: []const u8, img_header: *spng.spng_ihdr, buffer: []const u8) !void {
    const fd = c.fopen(path.ptr, "wb");
    defer {
        if (fd != null) {
            _ = c.fclose(fd);
        }
    }
    if (fd == null) {
        return ImgFilterError.CouldNotOpenFile;
    }
    const ctx = spng.spng_ctx_new(spng.SPNG_CTX_ENCODER) orelse return ImgFilterError.CouldNotCreatePngCtx;
    defer spng.spng_ctx_free(ctx);
    _ = spng.spng_set_png_file(ctx, @ptrCast(fd));
    _ = spng.spng_set_ihdr(ctx, img_header);

    const status = spng.spng_encode_image(
        ctx,
        buffer.ptr,
        buffer.len,
        spng.SPNG_FMT_PNG,
        spng.SPNG_ENCODE_FINALIZE,
    );

    if (status != 0) {
        return ImgFilterError.CouldNotEncodeImg;
    }
}

fn applyFilter(buffer: []u8) !void {
    const len = buffer.len;
    const red_f: f16 = 0.2126;
    const green_f: f16 = 0.7152;
    const blue_f: f16 = 0.0722;

    var index: u64 = 0;
    while (index < len) : (index += 4) {
        const rf: f16 = @floatFromInt(buffer[index]);
        const gf: f16 = @floatFromInt(buffer[index + 1]);
        const bf: f16 = @floatFromInt(buffer[index + 2]);

        const p = (red_f * rf) +
            (green_f * gf) + (blue_f * bf);

        buffer[index] = @intFromFloat(p);
        buffer[index + 1] = @intFromFloat(p);
        buffer[index + 2] = @intFromFloat(p);
    }
}

fn readImg(ctx: *spng.spng_ctx, buffer: []u8) !void {
    const status = spng.spng_decode_image(
        ctx,
        buffer.ptr,
        buffer.len,
        spng.SPNG_FMT_RGBA8,
        0,
    );

    if (status != 0) {
        return ImgFilterError.CouldNotDecodeImg;
    }
}

fn getImgHeader(ctx: *spng.spng_ctx) !spng.spng_ihdr {
    var img_header: spng.spng_ihdr = undefined;
    if (spng.spng_get_ihdr(ctx, &img_header) != 0) {
        return ImgFilterError.CouldNotGetImgHeader;
    }

    return img_header;
}

fn getImgSize(ctx: *spng.spng_ctx) !u64 {
    var out_size: u64 = 0;
    const status = spng.spng_decoded_image_size(ctx, spng.SPNG_FMT_RGBA8, &out_size);

    if (status != 0) {
        return ImgFilterError.CouldNotGetOutsize;
    }

    return out_size;
}
