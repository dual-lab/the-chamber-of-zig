const std = @import("std");
const cozypto_build = @import("cozypto/build.zig");
const cozstructure_build = @import("cozstructure/build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // S1: Subproject
    //// p1: cozypto
    cozypto_build.buildFromRoot(b, target, optimize);
    //// p2: cozstructure
    cozstructure_build.buildFromRoot(b, target, optimize);

    // S2: Clenup
    //// c1: artifact cleanup
    const clean = b.step("clean", "Clean up prooject generated file");
    clean.dependOn(&b.addRemoveDirTree(b.path("zig-out/")).step);
    //// c2: artifacto + cache
    const clobber = b.step(
        "clobber",
        "Clean up project generated files and zig cache",
    );
    clobber.dependOn(clean);
    clobber.dependOn(&b.addRemoveDirTree(b.path(".zig-cache/")).step);
}
