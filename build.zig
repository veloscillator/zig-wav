const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    b.addModule(.{
        .name = "wav",
        .source_file = .{ .path = "src/wav.zig" },
    });

    const test_step = b.step("test", "Run library tests");
    inline for ([_][]const u8{ "src/sample.zig", "src/wav.zig" }) |test_file| {
        const t = b.addTest(.{
            .root_source_file = .{ .path = test_file },
            .target = target,
            .optimize = optimize,
        });
        test_step.dependOn(&t.step);
    }
}
