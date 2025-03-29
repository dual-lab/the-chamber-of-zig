const std = @import("std");
const zigypto_build = @import("zigypto/build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // S1: Subproject
    //// p1: zigypto
    zigypto_build.buildFromRoot(b, target, optimize);

    // S2: Clenup
    //// c1: artifact cleanup
    ////// TODO: after study zip build system
    //// c2: artifacto + cache
    ////// TODO: after study zip build system
}
