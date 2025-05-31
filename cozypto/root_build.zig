const std = @import("std");
const builds = @import("../tools/builtins.zig");
const root_name = "cozypto";

pub fn buildFromRoot(
    b: *std.Build,
    t: std.Build.ResolvedTarget,
    o: std.builtin.OptimizeMode,
) void {
    // Create a custom build step
    const build_sub = b.step(root_name ++ "_build", "Build project");
    const cozcli_dep = b.dependency("cozcli", .{ .target = t, .optimize = o });
    const cozcli_mod = cozcli_dep.module("cozcli");
    const lib_mod = builds.addModule(
        b,
        t,
        o,
        root_name ++ "/src/root.zig",
        root_name,
        &[_]builds.Import{},
    );
    const lib = builds.createLib(b, lib_mod, .static, root_name);
    const install_lib_step = b.addInstallArtifact(lib, .{});

    const exe_mod = builds.createModule(
        b,
        t,
        o,
        root_name ++ "/src/main.zig",
        &[_]builds.Import{
            .{ .name = "cozcli", .mod = cozcli_mod },
            .{ .name = root_name, .mod = lib_mod },
        },
    );
    const exe = builds.createExe(b, exe_mod, root_name ++ "_exe");

    const install_exe = b.addInstallArtifact(exe, .{});

    build_sub.dependOn(&install_lib_step.step);
    build_sub.dependOn(&install_exe.step);

    // Create custom run step
    const run_step = b.step(root_name ++ "_run", "Run project");

    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    run_cmd.step.dependOn(&install_exe.step);

    run_step.dependOn(&run_cmd.step);

    // Crete custom run test step
    const test_step = b.step(root_name ++ "_test", "Run project test");
    builds.addTests(b, &[_]*std.Build.Module{ lib_mod, exe_mod }, test_step);
}
