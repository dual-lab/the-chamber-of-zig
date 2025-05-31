const std = @import("std");
const builds = @import("../tools/builtins.zig");
const root_name = "cozcli";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = builds.addModule(
        b,
        target,
        optimize,
        "src/root.zig",
        root_name,
        &[_]builds.Import{},
    );

    const lib = builds.createLib(b, lib_mod, .static, root_name);
    b.installArtifact(lib);

    builds.addTests(b, &[_]*std.Build.Module{lib_mod}, b.step("test", "Run unit test"));
}


