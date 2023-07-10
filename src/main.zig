const std = @import("std");
const log = std.log;

const c = @import("c");
const imgui = @import("imgui");

pub fn main() void {
    // Initialize SDL
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        log.err("SDL initialization failed: {s}", .{c.SDL_GetError()});
        return;
    }
    defer c.SDL_Quit();

    const window: *c.SDL_Window = c.SDL_CreateWindow("SDL Example", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, 800, 600, c.SDL_WINDOW_OPENGL) orelse {
        log.err("Failed to create window: {s}", .{c.SDL_GetError()});
        return;
    };
    defer c.SDL_DestroyWindow(window);

    const context: c.SDL_GLContext = c.SDL_GL_CreateContext(window) orelse {
        log.err("Failed to create OpenGL context: {s}", .{c.SDL_GetError()});
        return;
    };
    defer c.SDL_GL_DeleteContext(context);

    _ = imgui.CreateContext(.{});
    const io = imgui.GetIO();
    // io.*.ConfigFlags |= c.ImGuiConfigFlags_NavEnableKeyboard; // Enable Keyboard Controls
    // io.*.ConfigFlags |= c.ImGuiConfigFlags_NavEnableGamepad; // Enable Gamepad Controls
    imgui.StyleColorsDark(.{});

    // setup platform and renderer backends
    _ = imgui.sdl2.initForOpenGL(window, context);
    defer _ = imgui.sdl2.shutdown();
    _ = imgui.gl3.init(.{});
    defer _ = imgui.gl3.shutdown();

    var f: f32 = 0.0;
    var buf: [128:0]u8 = undefined;
    @memset(&buf, 0);

    var quit: bool = false;
    var event: c.SDL_Event = undefined;
    while (!quit) {
        while (c.SDL_PollEvent(&event) == 1) {
            if (event.type == c.SDL_QUIT) {
                quit = true;
            } else if (event.type == c.SDL_KEYDOWN) {
                if (event.key.keysym.sym == c.SDLK_ESCAPE) {
                    quit = true;
                }
            }
            _ = imgui.sdl2.processEvent(&event);
        }

        // start the Dear ImGui frame
        _ = imgui.gl3.newFrame();
        _ = imgui.sdl2.newFrame();
        imgui.NewFrame();

        imgui.ShowDemoWindow(.{});

        if (imgui.Begin("My Window", .{})) {
            // intended way varidact function will be handled
            _ = imgui.Text__VA("Hello, world %d", @as(c_int, 123));
            if (imgui.Button("Save", .{})) {}
            _ = imgui.InputText("string", &buf, buf.len, .{});
            _ = imgui.SliderFloat("float1", &f, 0, 1, .{});
        }
        imgui.End();

        // imgui rendering
        imgui.Render();
        c.glViewport(0, 0, @floatToInt(c_int, io.*.DisplaySize.x), @floatToInt(c_int, io.*.DisplaySize.y));
        c.glClearColor(0.2, 0.3, 0.4, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        _ = imgui.gl3.renderDrawData(imgui.GetDrawData());

        c.SDL_GL_SwapWindow(window);
    }
}
