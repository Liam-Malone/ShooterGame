const std = @import("std");
const graphics = @import("graphics.zig");
const c = @import("c.zig");

const Window = graphics.Window;
const Viewport = graphics.Viewport;
const Color = graphics.Color;
const Tilemap = graphics.Tilemap;

const FPS = 60;
const BACKGROUND_COLOR = Color.dark_gray;
const TEXTURE_PATH = "../../assets/textures/";
const WINDOW_WIDTH = 1200;
const WINDOW_HEIGHT = 1200;

fn set_render_color(renderer: *c.SDL_Renderer, col: c.SDL_Color) void {
    _ = c.SDL_SetRenderDrawColor(renderer, col.r, col.g, col.b, col.a);
}

var window_width: u32 = WINDOW_WIDTH;
var window_height: u32 = WINDOW_HEIGHT;
var quit: bool = false;
pub fn main() !void {
    var window: Window = try Window.init("ShooterGame", 0, 0, window_width, window_height);
    defer window.deinit();

    var viewport: Viewport = Viewport.init(0, 0, @intCast(window_width), @intCast(window_height));

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();
    var map = try Tilemap.init("../../assets/maps/initial_map", alloc);

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
                    's' => {
                        // save to file
                    },
                    ' ' => {},
                    else => {},
                },
                c.SDL_MOUSEBUTTONDOWN => switch (event.button.button) {
                    c.SDL_BUTTON_LEFT => {
                        // use current tool
                    },
                    else => {},
                },
                else => {},
            }
        }

        window.update();

        window_width = window.width;
        window_height = window.height;
        set_render_color(window.renderer, Color.make_sdl_color(BACKGROUND_COLOR));
        _ = c.SDL_RenderClear(window.renderer);

        map.render(window.renderer, &viewport);

        c.SDL_RenderPresent(window.renderer);

        c.SDL_Delay(1000 / FPS);
    }
}
