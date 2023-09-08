const std = @import("std");
const graphics = @import("graphics.zig");
const Window = graphics.Window;
const Color = graphics.Color;

const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
});

const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 600;
const FPS = 60;
const BACKGROUND_COLOR = Color.dark_gray;

fn set_render_color(renderer: *c.SDL_Renderer, col: c.SDL_Color) void {
    _ = c.SDL_SetRenderDrawColor(renderer, col.r, col.g, col.b, col.a);
}

var quit = false;
pub fn main() !void {
    var window: Window = try Window.init("ShooterGame", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);
    defer window.deinit();

    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    quit = true;
                },
                c.SDL_KEYDOWN => switch (event.key.keysym.sym) {
                    'q' => {
                        quit = true;
                    },
                    else => {},
                },
                else => {},
            }
        }

        set_render_color(window.renderer, Color.make_sdl_color(BACKGROUND_COLOR));
        _ = c.SDL_RenderClear(window.renderer);

        c.SDL_RenderPresent(window.renderer);
        c.SDL_Delay(1000 / FPS);
    }
}
