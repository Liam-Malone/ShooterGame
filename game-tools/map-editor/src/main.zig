const std = @import("std");
const graphics = @import("graphics.zig");
const gui = @import("gui.zig");
const c = @import("c.zig");

const Color = graphics.Color;
const TextureMap = graphics.TextureMap;
const Tilemap = graphics.Tilemap;
const TileID = graphics.TileID;
const Viewport = graphics.Viewport;
const Window = graphics.Window;

const DrawTools = enum { single, radius };

const FPS = 60;
const BACKGROUND_COLOR = Color.dark_gray;
const TEXTURE_PATH = "assets/textures/";
const WORLD_WIDTH = 2800;
const WORLD_HEIGHT = 2800;
const TILE_WIDTH = 10;
const TILE_HEIGHT = 10;

const THREAD_COUNT = 2;

fn set_render_color(renderer: *c.SDL_Renderer, col: c.SDL_Color) void {
    _ = c.SDL_SetRenderDrawColor(renderer, col.r, col.g, col.b, col.a);
}

fn brush(x: u32, y: u32, r: u32, tilemap: *Tilemap) void {
    var ix: i32 = @intCast(x);
    var iy: i32 = @intCast(y);
    const ir: i32 = @intCast(r);

    var a: i32 = 0;
    const max_x: i32 = @intCast(WORLD_WIDTH);
    const max_y: i32 = @intCast(WORLD_HEIGHT);
    while (a < ir) {
        const min_xval: u32 = @intCast(@max(ix - a, 0));
        const min_yval: u32 = @intCast(@max(iy - a, 0));
        const max_xval: u32 = @intCast(@min(ix + a, max_x));
        const max_yval: u32 = @intCast(@min(iy + a, max_y));

        if (min_xval == 0 or min_yval == 0 or max_xval == max_x or max_yval == max_y) return;
        place_at_pos(min_xval, min_yval, tilemap);
        place_at_pos(max_xval, max_yval, tilemap);
        a += 1;
    }
}

fn place_at_pos(x: u32, y: u32, tilemap: *Tilemap) void {
    tilemap.edit_tile(selected_id, x / (TILE_WIDTH), y / (TILE_HEIGHT));
}

fn save(tm: *Tilemap, alloc: std.mem.Allocator) !void {
    try tm.save(alloc);
}

var selected_id: TileID = TileID.grass;
var selected_tool = DrawTools.single;

var window_width: u32 = 800;
var window_height: u32 = 600;
var quit: bool = false;
pub fn main() !void {
    var window: Window = try Window.init("ShooterGame", 0, 0, window_width, window_height);
    defer window.deinit();

    var viewport: Viewport = Viewport.init(0, 0, @intCast(window_width), @intCast(window_height));

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(alloc);
    var arena_alloc = arena.allocator();
    var tex_map = try TextureMap.init(alloc, arena_alloc, window.renderer, @constCast(@ptrCast("assets/textures/")));
    defer tex_map.deinit();
    var tilemap: Tilemap = try Tilemap.init("assets/maps/next_test", alloc, &tex_map, TILE_WIDTH, TILE_HEIGHT, WORLD_WIDTH, WORLD_HEIGHT);

    const dumb_buttons = [_]gui.Button{
        gui.Button.init(30, 100, 30, 30, Color.blue, gui.ButtonID.SelectWater),
        gui.Button.init(60, 100, 30, 30, Color.green, gui.ButtonID.SelectGrass),
        gui.Button.init(30, 130, 30, 30, Color.stone, gui.ButtonID.SelectStone),
    };

    var clicked_button = false;
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
                    'w' => viewport.dy -= if (viewport.dy > -4) 2 else 0,
                    'a' => viewport.dx -= if (viewport.dx > -4) 2 else 0,
                    's' => {
                        if (event.key.keysym.mod & c.KMOD_CTRL != 0) {
                            var t = try std.Thread.spawn(.{}, save, .{ &tilemap, alloc });
                            t.detach();
                        } else {
                            viewport.dy += if (viewport.dy < 4) 2 else 0;
                        }
                    },
                    'd' => viewport.dx += if (viewport.dx < 4) 2 else 0,
                    'e' => {
                        // need to edit to let user select output file
                        if (event.key.keysym.mod & c.KMOD_CTRL != 0) {
                            var t = try std.Thread.spawn(.{}, save, .{ &tilemap, alloc });
                            t.detach();
                        } else {
                            // do something else, I guess
                        }
                    },
                    'n' => {
                        if (event.key.keysym.mod & c.KMOD_CTRL != 0) {
                            // prompt for creating new tilemap
                            // include: map dimension options
                        } else {
                            // some other use
                        }
                    },
                    '0' => selected_id = TileID.void,
                    '1' => selected_id = TileID.grass,
                    '2' => selected_id = TileID.stone,
                    '3' => selected_id = TileID.water,
                    ' ' => selected_tool = switch (selected_tool) {
                        DrawTools.single => DrawTools.radius,
                        DrawTools.radius => DrawTools.single,
                    },
                    else => {},
                },
                c.SDL_KEYUP => switch (event.key.keysym.sym) {
                    'w' => viewport.dy = if (viewport.dy < 0) 0 else viewport.dy,
                    's' => viewport.dy = if (viewport.dy > 0) 0 else viewport.dy,
                    'a' => viewport.dx = if (viewport.dx > 0) 0 else viewport.dx,
                    'd' => viewport.dx = if (viewport.dx > 0) 0 else viewport.dx,
                    else => {},
                },
                c.SDL_MOUSEBUTTONDOWN => switch (event.button.button) {
                    c.SDL_BUTTON_LEFT => {
                        for (dumb_buttons) |btn| {
                            if (btn.click(@intCast(event.button.x), @intCast(event.button.y))) |id| {
                                switch (id) {
                                    .SelectStone => selected_id = graphics.TileID.stone,
                                    .SelectGrass => selected_id = graphics.TileID.grass,
                                    .SelectWater => selected_id = graphics.TileID.water,
                                    .SelectDirt => selected_id = graphics.TileID.dirt,
                                }
                                clicked_button = true;
                            }
                        }
                        if (!clicked_button) {
                            const x = if (event.button.x + viewport.x > 0) @as(u32, @intCast(event.button.x + viewport.x)) else 0;
                            const y = if (event.button.y + viewport.y > 0) @as(u32, @intCast(event.button.y + viewport.y)) else 0;
                            switch (selected_tool) {
                                DrawTools.single => place_at_pos(x, y, &tilemap),
                                DrawTools.radius => brush(x, y, 8, &tilemap),
                            }
                            left_mouse_is_down = true;
                        }
                    },
                    else => {},
                },
                c.SDL_MOUSEBUTTONUP => switch (event.button.button) {
                    c.SDL_BUTTON_LEFT => {
                        left_mouse_is_down = false;
                        clicked_button = false;
                    },
                    else => {},
                },
                c.SDL_MOUSEMOTION => switch (left_mouse_is_down) {
                    true => {
                        const x = if (event.button.x + viewport.x > 0) @as(u32, @intCast(event.button.x + viewport.x)) else 0;
                        const y = if (event.button.y + viewport.y > 0) @as(u32, @intCast(event.button.y + viewport.y)) else 0;
                        switch (selected_tool) {
                            DrawTools.single => place_at_pos(x, y, &tilemap),
                            DrawTools.radius => brush(x, y, 10, &tilemap),
                        }
                        window.update();
                    },
                    false => {},
                },
                c.SDL_MOUSEWHEEL => {
                    viewport.dy = if (event.wheel.y > 0) -20 else if (event.wheel.y < 0) 20 else 0;
                    viewport.dx = if (event.wheel.x > 0) 20 else if (event.wheel.x < 0) -20 else 0;
                },
                else => {},
            }
        }

        window.update();
        viewport.update();

        window_width = window.width;
        window_height = window.height;
        set_render_color(window.renderer, Color.make_sdl_color(BACKGROUND_COLOR));
        _ = c.SDL_RenderClear(window.renderer);

        tilemap.render(window.renderer, &viewport, window);
        for (dumb_buttons) |btn| {
            btn.render(window.renderer);
        }

        c.SDL_RenderPresent(window.renderer);

        c.SDL_Delay(1000 / FPS);
    }
}
