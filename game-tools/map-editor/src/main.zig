const std = @import("std");
const graphics = @import("graphics.zig");
const c = @import("c.zig");

const Color = graphics.Color;
const TextureMap = graphics.TextureMap;
const Tilemap = graphics.Tilemap;
const Viewport = graphics.Viewport;
const Window = graphics.Window;

const FPS = 60;
const BACKGROUND_COLOR = Color.dark_gray;
const TEXTURE_PATH = "assets/textures/";
const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 600;
const TILE_WIDTH = 10;
const TILE_HEIGHT = 10;

fn set_render_color(renderer: *c.SDL_Renderer, col: c.SDL_Color) void {
    _ = c.SDL_SetRenderDrawColor(renderer, col.r, col.g, col.b, col.a);
}

// TODO: on-click, place tile at location
fn place_at_pos(x: u32, y: u32, tilemap: *Tilemap, tex_map: *TextureMap) !void {
    // maybe add error popup on fail?
    try tilemap.remove_tile(x / TILE_WIDTH, y / TILE_HEIGHT);
    if (selected_tiletype_id != 0) try tilemap.add_tile(selected_tiletype_id, x / TILE_WIDTH, y / TILE_HEIGHT, tex_map, TILE_WIDTH, TILE_HEIGHT);
}

var selected_tiletype_id: u32 = 1;

var window_width: u32 = WINDOW_WIDTH;
var window_height: u32 = WINDOW_HEIGHT;
var quit: bool = false;
pub fn main() !void {
    var window: Window = try Window.init("ShooterGame", 0, 0, window_width, window_height);
    defer window.deinit();

    var viewport: Viewport = Viewport.init(0, 0, @intCast(window_width), @intCast(window_height));

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();
    var tex_map = try TextureMap.init(alloc, window.renderer, TEXTURE_PATH);
    defer tex_map.deinit();
    //var tilemap = try Tilemap.init("assets/maps/initial_map", alloc, &tex_map, TILE_WIDTH, TILE_HEIGHT);
    var tilemap = try Tilemap.init("assets/maps/first_export", alloc, &tex_map, TILE_WIDTH, TILE_HEIGHT);
    defer tilemap.deinit();

    var left_mouse_is_down = false;
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
                        //tilemap.save();
                    },
                    'e' => {
                        //export
                        try tilemap.export_to_file("assets/maps/first_export", alloc);
                    },
                    '0' => selected_tiletype_id = 0,
                    '1' => selected_tiletype_id = 1,
                    '2' => selected_tiletype_id = 2,
                    ' ' => {},
                    else => {},
                },
                c.SDL_MOUSEBUTTONDOWN => switch (event.button.button) {
                    c.SDL_BUTTON_LEFT => {
                        // use current tool
                        const x = if (event.button.x > 0) @as(u32, @intCast(event.button.x)) else 0;
                        const y = if (event.button.y > 0) @as(u32, @intCast(event.button.y)) else 0;
                        try place_at_pos(x, y, &tilemap, &tex_map);
                        left_mouse_is_down = true;
                    },
                    else => {},
                },
                c.SDL_MOUSEBUTTONUP => switch (event.button.button) {
                    c.SDL_BUTTON_LEFT => {
                        left_mouse_is_down = false;
                    },
                    else => {},
                },
                c.SDL_MOUSEMOTION => switch (left_mouse_is_down) {
                    true => {
                        const x = if (event.button.x > 0) @as(u32, @intCast(event.button.x)) else 0;
                        const y = if (event.button.y > 0) @as(u32, @intCast(event.button.y)) else 0;
                        try place_at_pos(x, y, &tilemap, &tex_map);
                        window.update();
                    },
                    false => {},
                },
                else => {},
            }
        }

        window.update();

        window_width = window.width;
        window_height = window.height;
        set_render_color(window.renderer, Color.make_sdl_color(BACKGROUND_COLOR));
        _ = c.SDL_RenderClear(window.renderer);

        tilemap.render(window.renderer, &viewport);

        c.SDL_RenderPresent(window.renderer);

        c.SDL_Delay(1000 / FPS);
    }
}
