const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zlm = b.dependency("zlm", .{});

    const exe = b.addExecutable(.{
        .name = "zig_graph",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zlm", .module = zlm.module("zlm") },
            },
        }),
    });

    exe.linkLibC();

    b.installArtifact(exe);
}
