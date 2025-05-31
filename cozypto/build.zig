const std = @import("std");
const builds = @import("../tools/builtins.zig");
const root_name = "cozypto";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const cozcli_dep = b.dependency("cozcli", .{ .target = target, .optimize = optimize });
    const cozcli_mod = cozcli_dep.module("cozcli");

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

    const exe_mod = builds.createModule(
        b,
        target,
        optimize,
        "src/main.zig",
        &[_]builds.Import{
            .{ .name = "cozcli", .mod = cozcli_mod },
            .{ .name = root_name, .mod = lib_mod },
        },
    );

    const exe = builds.createExe(b, exe_mod, root_name ++ "_exe");
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    builds.addTests(b, &[_]*std.Build.Module{ lib_mod, exe_mod }, b.step("test", "Run unit test"));
}
