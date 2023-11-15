const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "map-editor",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    // --- COMMENTED OUT UNTIL I NEED TO FIGURE OUT DEPENDENCY STUFF --- //
    //if (exe.target.isWindows()) {
    //    exe.addIncludePath(
    //        .{ .path = "/home/liamm/dev-tools/windows/SDL2/x86_64-w64-mingw32/include" },
    //    );
    //    exe.addLibraryPath(
    //        .{ .path = "/home/liamm/dev-tools/windows/SDL2/x86_64-w64-mingw32/lib" },
    //    );
    //    if (!exe.target.isNative()) {
    //        exe.linkSystemLibrary("opengl32");
    //        exe.linkSystemLibrary("winmm");
    //        exe.linkSystemLibrary("ole32");
    //        exe.linkSystemLibrary("oleaut32");
    //        exe.linkSystemLibrary("gdi32");
    //        exe.linkSystemLibrary("setupapi");
    //        exe.linkSystemLibrary("imm32");
    //        exe.linkSystemLibrary("version");
    //        exe.linkSystemLibrary("rpcrt4");
    //    }
    //} else {
    //    exe.addIncludePath(
    //        .{ .path = "/usr/include" },
    //    );
    //    exe.addLibraryPath(
    //        .{ .path = "/usr/lib" },
    //    );
    //}

    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("SDL2_ttf");
    exe.linkSystemLibrary("SDL2_image");

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
