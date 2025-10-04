const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const options = .{
        .shared = b.option(
            bool,
            "shared",
            "Build GLFW as shared lib",
        ) orelse false,
        .enable_x11 = b.option(
            bool,
            "x11",
            "Whether to build with X11 support (default: true)",
        ) orelse true,
        .enable_wayland = b.option(
            bool,
            "wayland",
            "Whether to build with Wayland support (default: true)",
        ) orelse true,
        .enable_vulkan_import = b.option(
            bool,
            "import_vulkan",
            "Whether to build with external Vulkan dependency (default: false)",
        ) orelse false,
    };

    const options_step = b.addOptions();
    inline for (std.meta.fields(@TypeOf(options))) |field| {
        options_step.addOption(field.type, field.name, @field(options, field.name));
    }

    const options_module = options_step.createModule();

    const module = b.addModule("root", .{
        .root_source_file = b.path("src/zglfw.zig"),
        .imports = &.{
            .{ .name = "zglfw_options", .module = options_module },
        },
    });

    if (target.result.os.tag == .emscripten) return;

    const glfw = b.addLibrary(.{
        .name = "glfw",
        .linkage = if (options.shared) .dynamic else .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });

    if (options.shared and target.result.os.tag == .windows) {
        glfw.root_module.addCMacro("_GLFW_BUILD_DLL", "");
    }

    b.installArtifact(glfw);
    glfw.installHeadersDirectory(b.path("libs/glfw/include"), "", .{});

    addIncludePaths(b, glfw, target, options);
    linkSystemLibs(b, glfw, target, options);

    const src_dir = "libs/glfw/src/";
    switch (target.result.os.tag) {
        .windows => {
            glfw.addCSourceFiles(.{
                .files = &.{
                    src_dir ++ "platform.c",
                    src_dir ++ "monitor.c",
                    src_dir ++ "init.c",
                    src_dir ++ "vulkan.c",
                    src_dir ++ "input.c",
                    src_dir ++ "context.c",
                    src_dir ++ "window.c",
                    src_dir ++ "osmesa_context.c",
                    src_dir ++ "egl_context.c",
                    src_dir ++ "null_init.c",
                    src_dir ++ "null_monitor.c",
                    src_dir ++ "null_window.c",
                    src_dir ++ "null_joystick.c",
                    src_dir ++ "wgl_context.c",
                    src_dir ++ "win32_thread.c",
                    src_dir ++ "win32_init.c",
                    src_dir ++ "win32_monitor.c",
                    src_dir ++ "win32_time.c",
                    src_dir ++ "win32_joystick.c",
                    src_dir ++ "win32_window.c",
                    src_dir ++ "win32_module.c",
                },
                .flags = &.{"-D_GLFW_WIN32"},
            });
        },
        .macos => {
            glfw.addCSourceFiles(.{
                .files = &.{
                    src_dir ++ "platform.c",
                    src_dir ++ "monitor.c",
                    src_dir ++ "init.c",
                    src_dir ++ "vulkan.c",
                    src_dir ++ "input.c",
                    src_dir ++ "context.c",
                    src_dir ++ "window.c",
                    src_dir ++ "osmesa_context.c",
                    src_dir ++ "egl_context.c",
                    src_dir ++ "null_init.c",
                    src_dir ++ "null_monitor.c",
                    src_dir ++ "null_window.c",
                    src_dir ++ "null_joystick.c",
                    src_dir ++ "posix_thread.c",
                    src_dir ++ "posix_module.c",
                    src_dir ++ "posix_poll.c",
                    src_dir ++ "nsgl_context.m",
                    src_dir ++ "cocoa_time.c",
                    src_dir ++ "cocoa_joystick.m",
                    src_dir ++ "cocoa_init.m",
                    src_dir ++ "cocoa_window.m",
                    src_dir ++ "cocoa_monitor.m",
                },
                .flags = &.{"-D_GLFW_COCOA"},
            });
        },
        .linux => {
            glfw.addCSourceFiles(.{
                .files = &.{
                    src_dir ++ "platform.c",
                    src_dir ++ "monitor.c",
                    src_dir ++ "init.c",
                    src_dir ++ "vulkan.c",
                    src_dir ++ "input.c",
                    src_dir ++ "context.c",
                    src_dir ++ "window.c",
                    src_dir ++ "osmesa_context.c",
                    src_dir ++ "egl_context.c",
                    src_dir ++ "null_init.c",
                    src_dir ++ "null_monitor.c",
                    src_dir ++ "null_window.c",
                    src_dir ++ "null_joystick.c",
                    src_dir ++ "posix_time.c",
                    src_dir ++ "posix_thread.c",
                    src_dir ++ "posix_module.c",
                },
                .flags = &.{},
            });
            if (options.enable_x11 or options.enable_wayland) {
                glfw.addCSourceFiles(.{
                    .files = &.{
                        src_dir ++ "xkb_unicode.c",
                        src_dir ++ "linux_joystick.c",
                        src_dir ++ "posix_poll.c",
                    },
                    .flags = &.{},
                });
            }
            if (options.enable_x11) {
                glfw.addCSourceFiles(.{
                    .files = &.{
                        src_dir ++ "x11_init.c",
                        src_dir ++ "x11_monitor.c",
                        src_dir ++ "x11_window.c",
                        src_dir ++ "glx_context.c",
                    },
                    .flags = &.{},
                });
                glfw.root_module.addCMacro("_GLFW_X11", "1");
                glfw.linkSystemLibrary("X11");
            }
            if (options.enable_wayland) {
                glfw.addCSourceFiles(.{
                    .files = &.{
                        src_dir ++ "wl_init.c",
                        src_dir ++ "wl_monitor.c",
                        src_dir ++ "wl_window.c",
                    },
                    .flags = &.{},
                });
                glfw.addIncludePath(b.path(src_dir ++ "wayland"));
                glfw.root_module.addCMacro("_GLFW_WAYLAND", "1");
            }
        },
        else => {},
    }
    addIncludePaths(b, module, target, options);

    const test_step = b.step("test", "Run zglfw tests");
    const tests = b.addTest(.{
        .name = "zglfw-tests",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/zglfw.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    addIncludePaths(b, tests, target, options);
    linkSystemLibs(b, tests, target, options);
    tests.root_module.addImport("zglfw_options", options_module);
    tests.linkLibrary(glfw);
    b.installArtifact(tests);
    test_step.dependOn(&b.addRunArtifact(tests).step);
}

fn addIncludePaths(b: *std.Build, unit: anytype, target: std.Build.ResolvedTarget, options: anytype) void {
    unit.addIncludePath(b.path("libs/glfw/include"));
    switch (target.result.os.tag) {
        .linux => {
            if (b.lazyDependency("system_sdk", .{})) |system_sdk| {
                unit.addSystemIncludePath(system_sdk.path("linux/include"));
                if (options.enable_wayland) {
                    unit.addSystemIncludePath(system_sdk.path("linux/include/wayland"));
                }
            }
        },
        else => {},
    }
}

fn linkSystemLibs(b: *std.Build, compile_step: *std.Build.Step.Compile, target: std.Build.ResolvedTarget, options: anytype) void {
    compile_step.linkLibC();
    switch (target.result.os.tag) {
        .windows => {
            compile_step.linkSystemLibrary("gdi32");
            compile_step.linkSystemLibrary("user32");
            compile_step.linkSystemLibrary("shell32");
        },
        .macos => {
            if (b.lazyDependency("system_sdk", .{})) |system_sdk| {
                compile_step.addFrameworkPath(system_sdk.path("macos12/System/Library/Frameworks"));
                compile_step.addSystemIncludePath(system_sdk.path("macos12/usr/include"));
                compile_step.addLibraryPath(system_sdk.path("macos12/usr/lib"));
            }
            compile_step.linkSystemLibrary("objc");
            compile_step.linkFramework("IOKit");
            compile_step.linkFramework("CoreFoundation");
            compile_step.linkFramework("Metal");
            compile_step.linkFramework("AppKit");
            compile_step.linkFramework("CoreServices");
            compile_step.linkFramework("CoreGraphics");
            compile_step.linkFramework("Foundation");
        },
        .linux => {
            if (b.lazyDependency("system_sdk", .{})) |system_sdk| {
                if (target.result.cpu.arch.isX86()) {
                    compile_step.addLibraryPath(system_sdk.path("linux/lib/x86_64-linux-gnu"));
                } else {
                    compile_step.addLibraryPath(system_sdk.path("linux/lib/aarch64-linux-gnu"));
                }
                compile_step.addSystemIncludePath(system_sdk.path("linux/include"));
                compile_step.addSystemIncludePath(system_sdk.path("linux/include/wayland"));
            }
            if (options.enable_x11) {
                compile_step.root_module.addCMacro("_GLFW_X11", "1");
                compile_step.linkSystemLibrary("X11");
            }
            if (options.enable_wayland) {
                compile_step.root_module.addCMacro("_GLFW_WAYLAND", "1");
            }
        },
        else => {},
    }
}
