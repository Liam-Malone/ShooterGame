const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "Shooter-Game",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // --- COMMENTED OUT UNTIL I NEED TO FIGURE OUT DEPENDENCY STUFF --- //
    //if (exe.target.isDarwin() and exe.target.isNative()) {
    //    // assumes you used brew to install sdl2 and sdl2_ttf
    //    exe.addIncludePath(
    //        .{ .path = "/usr/local/include" },
    //    );
    //    exe.addLibraryPath(
    //        .{ .path = "/usr/local/lib" },
    //    );
    //} else if (exe.target.isWindows()) {
    //    exe.addIncludePath(
    //        .{ .path = "vendor/windows/SDL2/x86_64-w64-mingw32/include" },
    //    );
    //    exe.addLibraryPath(
    //        .{ .path = "vendor/windows/SDL2/x86_64-w64-mingw32/lib" },
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
    exe.linkSystemLibrary("SDL2_mixer");

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
