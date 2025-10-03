# [zglfw](https://github.com/zig-gamedev/zglfw)

Zig build package and bindings for [GLFW 3.4](https://github.com/glfw/glfw/releases/tag/3.4)

## Getting started

Example `build.zig`:
```zig
pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{ ... });

    const zglfw = b.dependency("zglfw", .{});
    exe.root_module.addImport("zglfw", zglfw.module("root"));

    if (target.result.os.tag != .emscripten) {
        exe.linkLibrary(zglfw.artifact("glfw"));
    }
}
```

Now in your code you may import and use `zglfw`:
```zig
const glfw = @import("zglfw");

pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();

    const window = try glfw.createWindow(600, 600, "zig-gamedev: minimal_glfw_gl", null);
    defer glfw.destroyWindow(window);

    // or, using the equivalent, encapsulated, "objecty" API:
    const window = try glfw.Window.create(600, 600, "zig-gamedev: minimal_glfw_gl", null);
    defer window.destroy();

    // setup your graphics context here

    while (!window.shouldClose()) {
        glfw.pollEvents();

        // render your things here

        window.swapBuffers();
    }
}
```

See [zig-gamedev samples](https://github.com/zig-gamedev/zig-gamedev/tree/main/samples) for more complete usage examples.


## Usage with Vulkan

To match types from `zglfw` functions and Vulkan library `import_vulkan` option may be used. When using this option `vulkan` import must be provided to the root module.

Example `build.zig` with [`vulkan-zig`](https://github.com/Snektron/vulkan-zig):

```zig
const vulkan_headers = b.dependency("vulkan_headers");
const vulkan = b.dependency("vulkan_zig", .{
    .registry = vulkan_headers.path("registry/vk.xml"),
}).module("vulkan-zig");


const zglfw = b.dependency("zglfw", .{ .import_vulkan = true });

const zglfw_mod = zglfw.module("root");
zglfw_mod.addImport("vulkan", vulkan);

const exe = b.addExecutable(.{
    .name = "vk_setup",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "zglfw", .module = zglfw_mod },
            .{ .name = "vulkan", .module = vulkan },
        },
    }),
});

exe.root_module.addImport("vulkan", vulkan);
exe.root_module.linkLibrary(zglfw.artifact("glfw"));

```
