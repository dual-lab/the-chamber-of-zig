const std = @import("std");
const builds = @import("../tools/builtins.zig");
const root_name = "cozimg";

pub fn buildFromRoot(
    b: *std.Build,
    t: std.Build.ResolvedTarget,
    o: std.builtin.OptimizeMode,
) void {
    // Create a custom build step
    const build_sub = b.step(root_name ++ "_build", "Build project");

    const c_translate = builds.translateSystemC(
        b,
        t,
        o,
        "/usr/include/stdio.h",
    );

    c_translate.defineCMacro("_NO_CRT_STDIO_INLINE", "1");
    const c_translate_mod = c_translate.createModule();

    const spng_translate = builds.translateSystemC(
        b,
        t,
        o,
        "/usr/local/include/spng.h",
    );
    const spng_translate_mod = spng_translate.createModule();

    const lib_mod = builds.addModule(
        b,
        t,
        o,
        root_name ++ "/src/root.zig",
        root_name,
        &[_]builds.Import{
            .{ .name = "c", .mod = c_translate_mod },
            .{ .name = "spng", .mod = spng_translate_mod },
        },
    );

    const lib = builds.createLib(b, lib_mod, .static, root_name);
    const install_lib_step = b.addInstallArtifact(lib, .{});

    const exe_mod = builds.createModule(
        b,
        t,
        o,
        root_name ++ "/src/main.zig",
        &[_]builds.Import{.{ .mod = lib_mod, .name = root_name }},
    );
    exe_mod.addImport("c", c_translate_mod);
    exe_mod.addImport("spng", spng_translate_mod);

    const exe = builds.createExe(b, exe_mod, root_name ++ "_exe");
    exe.linkLibC();
    exe.linkSystemLibrary("spng");

    const install_exe = b.addInstallArtifact(exe, .{});

    install_lib_step.step.dependOn(&c_translate.step);
    install_lib_step.step.dependOn(&spng_translate.step);
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
