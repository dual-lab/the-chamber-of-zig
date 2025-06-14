const std = @import("std");
const builds = @import("../tools/builtins.zig");
const root_name = "cozimg";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const c_translate = builds.translateSystemC(
        b,
        target,
        optimize,
        "/usr/include/stdio.h",
    );

    c_translate.defineCMacro("_NO_CRT_STDIO_INLINE", "1");
    const c_translate_mod = c_translate.createModule();

    const spng_translate = builds.translateSystemC(
        b,
        target,
        optimize,
        "/usr/local/include/spng.h",
    );
    const spng_translate_mod = spng_translate.createModule();

    const lib_mod = builds.addModule(
        b,
        target,
        optimize,
        "src/root.zig",
        root_name,
        &[_]builds.Import{
            .{ .name = "c", .mod = c_translate_mod },
            .{ .name = "spng", .mod = spng_translate_mod },
        },
    );

    const lib = builds.createLib(b, lib_mod, .static, root_name);
    b.installArtifact(lib);

    const exe_mod = builds.createModule(
        b,
        target,
        optimize,
        "src/main.zig",
        &[_]builds.Import{.{ .mod = lib_mod, .name = root_name }},
    );
    exe_mod.addImport("c", c_translate_mod);
    exe_mod.addImport("spng", spng_translate_mod);

    const exe = builds.createExe(b, exe_mod, root_name ++ "_exe");
    exe.linkLibC();
    exe.linkSystemLibrary("spng");
    b.installArtifact(exe);

    b.getInstallStep().dependOn(&c_translate.step);
    b.getInstallStep().dependOn(&spng_translate.step);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    builds.addTests(b, &[_]*std.Build.Module{ lib_mod, exe_mod }, b.step("test", "Run unit test"));
}
