const std = @import("std");
const root_name = "cozstructure";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = addModule(b, target, optimize, "src/root.zig");

    const lib = createLib(b, lib_mod);
    b.installArtifact(lib);

    addTests(
        b,
        &[_]*std.Build.Module{lib_mod},
        b.step("test", "Run unit test"),
    );
}

pub fn buildFromRoot(
    b: *std.Build,
    t: std.Build.ResolvedTarget,
    o: std.builtin.OptimizeMode,
) void {
    // Create a custom build step
    const build_sub = b.step(root_name ++ "_build", "Build project");
    const lib_mod = addModule(b, t, o, root_name ++ "/src/root.zig");
    const lib = createLib(b, lib_mod);
    const install_lib_step = b.addInstallArtifact(lib, .{});

    build_sub.dependOn(&install_lib_step.step);


    // Crete custom run test step
    const test_step = b.step(root_name ++ "_test", "Run project test");
    addTests(
        b,
        &[_]*std.Build.Module{
            lib_mod,
        },
        test_step,
    );
}

fn createLib(b: *std.Build, m: *std.Build.Module) *std.Build.Step.Compile {
    return b.addLibrary(.{
        .linkage = .static,
        .name = root_name,
        .root_module = m,
    });
}


fn addModule(
    b: *std.Build,
    t: std.Build.ResolvedTarget,
    o: std.builtin.OptimizeMode,
    src: []const u8,
) *std.Build.Module {
    const lib_mod = b.addModule(root_name, .{
        .root_source_file = b.path(src),
        .target = t,
        .optimize = o,
    });

    return lib_mod;
}

fn createModule(
    b: *std.Build,
    t: std.Build.ResolvedTarget,
    o: std.builtin.OptimizeMode,
    src: []const u8,
    imports: []const *std.Build.Module,
) *std.Build.Module {
    const exe_mod = b.createModule(.{
        .root_source_file = b.path(src),
        .target = t,
        .optimize = o,
    });

    for (imports) |i| {
        exe_mod.addImport(root_name, i);
    }

    return exe_mod;
}

fn addTests(b: *std.Build, mods: []const *std.Build.Module, s: *std.Build.Step) void {
    for (mods) |mod| {
        const unit_test = b.addTest(.{ .root_module = mod });
        const run_test = b.addRunArtifact(unit_test);
        s.dependOn(&run_test.step);
    }
}

