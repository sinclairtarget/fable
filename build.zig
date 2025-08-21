const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize_mode: std.builtin.OptimizeMode = switch (b.release_mode) {
        .off => .Debug,
        .any => .Debug,
        .fast => .ReleaseFast,
        .safe => .ReleaseSafe,
        .small => .ReleaseSmall,
    };

    const exe = b.addExecutable(.{
        .name = "fl",
        .root_source_file = b.path("src/main.zig"),
        .target = b.graph.host,
        .optimize = optimize_mode,
    });

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
