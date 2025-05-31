const std = @import("std");
const builds = @import("../tools/builtins.zig");
const root_name = "cozcli";

pub fn buildFromRoot(
    b: *std.Build,
    t: std.Build.ResolvedTarget,
    o: std.builtin.OptimizeMode,
) void {
    // Create a custom build step
    const build_sub = b.step(root_name ++ "_build", "Build project");
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

    build_sub.dependOn(&install_lib_step.step);

    // Crete custom run test step
    const test_step = b.step(root_name ++ "_test", "Run project test");
    builds.addTests(b, &[_]*std.Build.Module{lib_mod}, test_step);
}
