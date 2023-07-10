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
        .name = "simple",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "./src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    // hides the console
    //exe.subsystem = std.Target.SubSystem.Windows;

    const c_mod = b.addModule("c", .{ .source_file = .{ .path = "src/c.zig" } });

    const cpp_mod = b.addModule("cpp", .{ .source_file = .{ .path = "lib/cpp.zig" } });
    const imgui_mod = b.addModule("imgui", .{
        .source_file = .{ .path = "lib/imgui/imgui.zig" },
        .dependencies = &.{
            .{ .name = "c", .module = c_mod },
            .{ .name = "cpp", .module = cpp_mod },
        },
    });

    // other single headers libs
    exe.addIncludePath("./lib");
    exe.addModule("c", c_mod);
    exe.addModule("imgui", imgui_mod);
    exe.addModule("cpp", cpp_mod);

    // include, link and install sdl2
    exe.linkLibC();
    exe.addIncludePath("./lib/SDL2/include");
    exe.addLibraryPath("./lib/SDL2/lib/msvc/x64");
    exe.linkSystemLibraryName("SDL2");
    exe.linkSystemLibraryName("SDL2main");
    b.installFile("./lib/SDL2/lib/msvc/x64/SDL2.dll", "bin/SDL2.dll");

    // link opengl
    exe.linkSystemLibraryName("opengl32");

    // build imgui
    const imgui_lib = b.addStaticLibrary(.{
        .name = "imgui",
        .target = target,
        .optimize = optimize,
    });
    imgui_lib.addIncludePath("./lib/imgui");
    imgui_lib.addIncludePath("./lib/imgui/backends");
    imgui_lib.linkLibC();
    imgui_lib.linkLibCpp();
    const cflags = &.{"-fno-sanitize=undefined"};
    imgui_lib.addCSourceFile("./lib/imgui/imgui.cpp", cflags);
    imgui_lib.addCSourceFile("./lib/imgui/imgui_widgets.cpp", cflags);
    imgui_lib.addCSourceFile("./lib/imgui/imgui_tables.cpp", cflags);
    imgui_lib.addCSourceFile("./lib/imgui/imgui_draw.cpp", cflags);
    imgui_lib.addCSourceFile("./lib/imgui/imgui_demo.cpp", cflags);
    // plot
    // imgui_lib.addCSourceFile("/lib/imgui/src/implot_demo.cpp", cflags);
    // imgui_lib.addCSourceFile("/lib/imgui/src/implot.cpp", cflags);
    // imgui_lib.addCSourceFile("/lib/imgui/src/implot_items.cpp", cflags);
    // backends
    imgui_lib.addIncludePath("./lib/SDL2/include");
    imgui_lib.addCSourceFile("./lib/imgui/backends/imgui_impl_opengl3.cpp", cflags);
    imgui_lib.addCSourceFile("./lib/imgui/backends/imgui_impl_sdl2.cpp", cflags);
    // glue
    imgui_lib.addCSourceFile("./lib/imgui/imgui_glue.cpp", cflags);
    imgui_lib.addCSourceFile("./lib/imgui/imgui_impl_opengl3_glue.cpp", cflags);
    imgui_lib.addCSourceFile("./lib/imgui/imgui_impl_sdl2_glue.cpp", cflags);
    exe.linkLibrary(imgui_lib);

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
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
