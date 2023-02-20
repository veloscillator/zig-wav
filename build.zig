const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.build.Builder) void {
    if (comptime builtin.zig_version.minor < 11) {
        const mode = b.standardReleaseOptions();

        const test_step = b.step("test", "Run library tests");

        for ([_][]const u8{ "src/sample.zig", "src/wav.zig" }) |test_file| {
            const t = b.addTest(test_file);
            t.setBuildMode(mode);
            test_step.dependOn(&t.step);
        }
        return;
    }

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const test_step = b.step("test", "Run library tests");

    for ([_][]const u8{ "src/sample.zig", "src/wav.zig" }) |test_file| {
        const t = b.addTest(.{
            .root_source_file = .{ .path = test_file },
            .target = target,
            .optimize = optimize,
        });
        test_step.dependOn(&t.step);
    }
}
