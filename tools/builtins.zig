const std = @import("std");

pub fn createLib(
    b: *std.Build,
    m: *std.Build.Module,
    linkage: std.builtin.LinkMode,
    name: []const u8,
) *std.Build.Step.Compile {
    return b.addLibrary(.{
        .linkage = linkage,
        .name = name,
        .root_module = m,
    });
}

pub fn createExe(
    b: *std.Build,
    m: *std.Build.Module,
    name: []const u8,
) *std.Build.Step.Compile {
    return b.addExecutable(.{
        .name = name,
        .root_module = m,
    });
}

pub fn addModule(
    b: *std.Build,
    t: std.Build.ResolvedTarget,
    o: std.builtin.OptimizeMode,
    src: []const u8,
    name: []const u8,
) *std.Build.Module {
    const lib_mod = b.addModule(name, .{
        .root_source_file = b.path(src),
        .target = t,
        .optimize = o,
    });

    return lib_mod;
}

pub fn createModule(
    b: *std.Build,
    t: std.Build.ResolvedTarget,
    o: std.builtin.OptimizeMode,
    src: []const u8,
    imports: []const *std.Build.Module,
    name: []const u8,
) *std.Build.Module {
    const exe_mod = b.createModule(.{
        .root_source_file = b.path(src),
        .target = t,
        .optimize = o,
    });

    for (imports) |i| {
        exe_mod.addImport(name, i);
    }

    return exe_mod;
}

pub fn addTests(
    b: *std.Build,
    mods: []const *std.Build.Module,
    s: *std.Build.Step,
) void {
    for (mods) |mod| {
        const unit_test = b.addTest(.{ .root_module = mod });
        const run_test = b.addRunArtifact(unit_test);
        s.dependOn(&run_test.step);
    }
}
