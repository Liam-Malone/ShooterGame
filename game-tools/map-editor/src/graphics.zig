const std = @import("std");
const c = @import("c.zig");

const print = std.debug.print;

const FONT_FILE = @embedFile("DejaVuSans.ttf");
const PIXEL_BUFFER = 1;
const TILE_WIDTH = 8;
const TILE_HEIGHT = 8;

pub const Color = enum(u32) {
    white = 0xFFFFFFFF,
    purple = 0x7BF967AA,
    red = 0xFC1A17CC,
    dark_gray = 0xFF181818,
    grass = 0x00FF00FF,
    dirt = 0xBBBBBBFF,
    wood = 0xBBBBBBAA,
    stone = 0xFF1818FF,
    leaves = 0x00FF0088,

    pub fn make_sdl_color(col: Color) c.SDL_Color {
        var color = @intFromEnum(col);
        const r: u8 = @truncate((color >> (0 * 8)) & 0xFF);
        const g: u8 = @truncate((color >> (1 * 8)) & 0xFF);
        const b: u8 = @truncate((color >> (2 * 8)) & 0xFF);
        const a: u8 = @truncate((color >> (3 * 8)) & 0xFF);

        return c.SDL_Color{
            .r = r,
            .g = g,
            .b = b,
            .a = a,
        };
    }
};

const DisplayMode = enum {
    windowed,
    fullscreen_desktop,
    fullscreen,
};

const TileID = enum(u32) {
    grass = 0,
    stone = 1,
    dirt = 2,
    wood = 3,
    leaves = 4,

    pub fn create(id: u32) !TileID {
        switch (id) {
            0 => {
                return TileID.grass;
            },
            1 => {
                return TileID.stone;
            },
            2 => {
                return TileID.dirt;
            },
            3 => {
                return TileID.wood;
            },
            4 => {
                return TileID.leaves;
            },
            else => {
                unreachable;
            },
        }
    }
};
const Tile = struct {
    w: f32 = TILE_WIDTH,
    h: f32 = TILE_HEIGHT,
    x: f32,
    y: f32,
    id: TileID,

    pub fn init(id: u32, x: u32, y: u32) Tile {
        return Tile{
            .x = @as(f32, @floatFromInt(x)) * TILE_WIDTH,
            .y = @as(f32, @floatFromInt(y)) * TILE_HEIGHT,
            .id = try TileID.create(id),
        };
    }
    pub fn get_color(self: *Tile) Color {
        var col: Color = undefined;
        switch (self.id) {
            TileID.grass => {
                col = Color.grass;
            },
            TileID.dirt => {
                col = Color.dirt;
            },
            TileID.wood => {
                col = Color.wood;
            },
            TileID.stone => {
                col = Color.stone;
            },
            TileID.leaves => {
                col = Color.leaves;
            },
        }
        return col;
    }
};
pub const Tilemap = struct {
    tiles: [][]Tile,

    //
    pub fn init(filepath: []const u8, allocator: std.mem.Allocator) !Tilemap {
        print("\ntrying path: {s}\n", .{filepath});
        const tiles = try load_from_file(filepath, allocator);
        var tile_count: usize = 0;
        for (tiles) |row| {
            for (row) |tile| {
                _ = tile;
                tile_count += 1;
            }
        }
        print("\n**DEBUG PRINTING TILEMAP**\n\t(tile count: {d})\t\n", .{tile_count});
        try print_map(tiles);
        return Tilemap{
            .tiles = tiles,
        };
    }

    //******************************************************//
    //                   LOAD CUSTOM TILEMAP                //
    //    ---------------------------------------------     //
    //        tilemap file will be something like:          //
    //                                                      //
    //                0 1 0 0 0 0 0 0 1 0                   //
    //                0 1 1 1 1 1 1 1 1 1                   //
    //                0 0 0 0 0 1 1 0 0 0                   //
    //                                                      //
    //                                                      //
    //    function should read in file line by line and     //
    //    sort int values into the appropriate Tile enum    //
    //    values, collecting into an arraylist, then to     //
    //    an array of Tiles, which is to be added to the    //
    //    arraylist, and subsequently, the array, of        //
    //    Tile arrays, which will determine the map.        //
    //******************************************************//

    fn load_from_file(filepath: []const u8, allocator: std.mem.Allocator) ![][]Tile {
        // read in one line at a time, sort into map based on numerical value
        var map_maker = std.ArrayList([]Tile).init(allocator);
        defer map_maker.deinit();
        const data = try std.fs.cwd().readFileAlloc(allocator, filepath, 250);
        defer allocator.free(data);
        var iter_lines = std.mem.split(u8, data, "\n");
        var ypos: u32 = 0;
        while (iter_lines.next()) |line| {
            var tile_arr = std.ArrayList(Tile).init(allocator);
            defer tile_arr.deinit();
            var iter_inner = std.mem.split(u8, line, " ");
            var xpos: u32 = 0;
            while (iter_inner.next()) |val| {
                if (val.len != 0) {
                    const int_val: u32 = try std.fmt.parseInt(u32, val, 10);
                    try tile_arr.append(Tile.init(int_val, xpos, ypos));
                    xpos += 1;
                }
            }
            const arr: []Tile = try tile_arr.toOwnedSlice();
            try map_maker.append(arr);
            ypos += 1;
        }
        const tilemap: [][]Tile = try map_maker.toOwnedSlice();
        return tilemap;
    }

    pub fn render(self: *Tilemap, renderer: *c.SDL_Renderer, vp: *Viewport) void {
        for (0..self.tiles.len) |i| {
            for (0..self.tiles[i].len) |j| {
                const tile = self.tiles[i][j];
                if (vp.can_see(@intFromFloat(tile.x), @intFromFloat(tile.y), @intFromFloat(tile.w), @intFromFloat(tile.h))) {
                    const rect = c.SDL_Rect{
                        .x = @as(c_int, @intFromFloat(tile.x)) - vp.x,
                        .y = @as(c_int, @intFromFloat(tile.y)) - vp.y,
                        .w = @as(c_int, @intFromFloat(tile.w)),
                        .h = @as(c_int, @intFromFloat(tile.h)),
                    };
                    set_render_color(renderer, Color.make_sdl_color(self.tiles[i][j].get_color()));
                    _ = c.SDL_RenderFillRect(renderer, &rect);
                }
                // render tile
            }
        }
    }

    // debug purposes
    fn print_map(map: [][]Tile) !void {
        for (map) |arr| {
            for (arr) |tile| {
                print("{any} ", .{tile});
            }
            print("\n", .{});
        }
    }
};

pub const Viewport = struct {
    x: i32,
    y: i32,
    w: i32,
    h: i32,
    rect: c.SDL_Rect,
    dx: i32 = 0,
    dy: i32 = 0,

    pub fn init(x: i32, y: i32, width: i32, height: i32) Viewport {
        return Viewport{
            .x = x,
            .y = y,
            .w = width,
            .h = height,
            .rect = c.SDL_Rect{
                .x = @as(c_int, x),
                .y = @as(c_int, y),
                .w = @as(c_int, width),
                .h = @as(c_int, height),
            },
        };
    }
    pub fn update(self: *Viewport, destx: i32, desty: i32, max_x: i32, max_y: i32) void {
        const xdiff = destx - @divExact(self.w, 2);
        const ydiff = desty - @divExact(self.h, 2);

        if (xdiff != self.x) {
            const diff: i32 = @divFloor(xdiff - self.x, 3);
            self.dx = if (self.x + diff > 0 and self.x + self.w + diff < max_x) diff else 0;
        } else self.dx = 0;

        if (ydiff != self.y) {
            const diff = @divFloor(ydiff - self.y, 3);
            self.dy = if (self.y + diff > 0 and self.y + self.h + diff < max_y) diff else 0;
        } else self.dy = 0;

        self.x += self.dx;
        self.y += self.dy;
        self.rect = c.SDL_Rect{
            .x = @as(c_int, self.x),
            .y = @as(c_int, self.y),
            .w = @as(c_int, self.w),
            .h = @as(c_int, self.h),
        };
    }
    pub fn can_see(self: *Viewport, x: i32, y: i32, w: i32, h: i32) bool {
        if ((x + w > self.x or x > self.x + self.w) and (y + h > self.y or y < self.y + self.h)) return true;
        return false;
    }
};

pub const ScreenText = struct {
    x: f32,
    y: f32,
    color: Color,
    font_rw: *c.SDL_RWops,
    font: *c.TTF_Font,
    font_rect: c.SDL_Rect,
    surface: *c.SDL_Surface,
    tex: *c.SDL_Texture,

    pub fn init(x: f32, y: f32, font_size: c_int, color: Color, msg: []const u8, renderer: *c.SDL_Renderer) !ScreenText {
        const font_rw = c.SDL_RWFromConstMem(
            @ptrCast(&FONT_FILE[0]),
            @intCast(FONT_FILE.len),
        ) orelse {
            c.SDL_Log("Unable to get RWFromConstMem: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        const font = c.TTF_OpenFontRW(font_rw, 0, font_size) orelse {
            c.SDL_Log("Unable to load font: %s", c.TTF_GetError());
            return error.SDLInitializationFailed;
        };
        var font_surface = c.TTF_RenderUTF8_Solid(
            font,
            @ptrCast(msg),
            Color.make_sdl_color(color),
        ) orelse {
            c.SDL_Log("Unable to render text: %s", c.TTF_GetError());
            return error.SDLInitializationFailed;
        };
        var font_rect: c.SDL_Rect = .{
            .w = font_surface.*.w,
            .h = font_surface.*.h,
            .x = @intFromFloat(x),
            .y = @intFromFloat(y),
        };
        var font_tex = c.SDL_CreateTextureFromSurface(renderer, font_surface) orelse {
            c.SDL_Log("Unable to create texture: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        return ScreenText{
            .x = x,
            .y = y,
            .font_rw = font_rw,
            .font = font,
            .color = color,
            .surface = font_surface,
            .tex = font_tex,
            .font_rect = font_rect,
        };
    }

    pub fn deinit(self: *ScreenText) void {
        defer std.debug.assert(c.SDL_RWclose(self.font_rw) == 0);
        defer c.TTF_CloseFont(self.font);
        defer c.SDL_FreeSurface(self.surface);
        defer c.SDL_DestroyTexture(self.tex);
    }

    pub fn render(self: *ScreenText, renderer: *c.SDL_Renderer, msg: []const u8) !void {
        self.surface = c.TTF_RenderUTF8_Solid(
            self.font,
            @ptrCast(msg),
            Color.make_sdl_color(self.color),
        ) orelse {
            c.SDL_Log("Unable to render text: %s", c.TTF_GetError());
            return error.SDLInitializationFailed;
        };

        self.font_rect = c.SDL_Rect{
            .x = @intFromFloat(self.x),
            .y = @intFromFloat(self.y),
            .w = self.surface.*.w,
            .h = self.surface.*.h,
        };

        self.tex = c.SDL_CreateTextureFromSurface(renderer, self.surface) orelse {
            c.SDL_Log("Unable to create texture: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        _ = c.SDL_RenderCopy(renderer, self.tex, null, &self.font_rect);
    }
};

pub const Window = struct {
    window: *c.SDL_Window,
    renderer: *c.SDL_Renderer,
    width: u32,
    height: u32,
    mode: DisplayMode = DisplayMode.windowed,

    pub fn init(name: []const u8, xpos: u8, ypos: u8, width: u32, height: u32) !Window {
        if (c.SDL_Init(c.SDL_INIT_VIDEO) < 0) {
            c.SDL_Log("Unable to initialize SDL: {s}\n", c.SDL_GetError());
            return error.SDLInitializationFailed;
        }

        if (c.TTF_Init() < 0) {
            c.SDL_Log("Unable to initialize SDL: {s}\n", c.SDL_GetError());
        }

        const window = c.SDL_CreateWindow(@ptrCast(name), @intCast(xpos), @intCast(ypos), @intCast(width), @intCast(height), 0) orelse {
            c.SDL_Log("Unable to initialize SDL: {s}\n", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };
        const renderer = c.SDL_CreateRenderer(window, -1, c.SDL_RENDERER_ACCELERATED) orelse {
            c.SDL_Log("Unable to initialize SDL: {s}\n", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };
        return Window{
            .window = window,
            .renderer = renderer,
            .width = width,
            .height = height,
        };
    }

    pub fn deinit(self: *Window) void {
        defer c.SDL_Quit();
        defer c.TTF_Quit();
        defer c.SDL_DestroyWindow(@ptrCast(self.window));
        defer c.SDL_DestroyRenderer(self.renderer);
    }

    pub fn set_fullscreen(self: *Window, fullscreen_type: u32) void {
        switch (fullscreen_type) {
            0 => {
                _ = c.SDL_SetWindowFullscreen(self.window, 0);
                self.mode = DisplayMode.windowed;
            },
            1 => {
                _ = c.SDL_SetWindowFullscreen(self.window, c.SDL_WINDOW_FULLSCREEN);
                self.mode = DisplayMode.fullscreen;
            },
            2 => {
                _ = c.SDL_SetWindowFullscreen(self.window, c.SDL_WINDOW_FULLSCREEN_DESKTOP);
                self.mode = DisplayMode.fullscreen_desktop;
            },
            else => {},
        }
    }

    pub fn toggle_fullscreen(self: *Window) void {
        switch (self.mode) {
            DisplayMode.fullscreen => {
                self.set_fullscreen(0);
                print("go windowed\n", .{});
            },
            DisplayMode.fullscreen_desktop => {
                self.set_fullscreen(1);
                print("go fullscreen\n", .{});
            },
            DisplayMode.windowed => {
                self.set_fullscreen(2);
                print("go full desktop\n", .{});
            },
        }
    }

    fn window_size(self: *Window) void {
        var w: c_int = undefined;
        var h: c_int = undefined;
        _ = c.SDL_GetWindowSize(self.window, @ptrCast(&w), @ptrCast(&h));
        self.width = @intCast(w);
        self.height = @intCast(h);
    }
    pub fn update(self: *Window) void {
        window_size(self);
    }
};

fn set_render_color(renderer: *c.SDL_Renderer, col: c.SDL_Color) void {
    _ = c.SDL_SetRenderDrawColor(renderer, col.r, col.g, col.b, col.a);
}

pub fn make_sdl_rect(x: f32, y: f32, w: f32, h: f32) c.SDL_Rect {
    return c.SDL_Rect{
        .x = @intFromFloat(x),
        .y = @intFromFloat(y),
        .w = @intFromFloat(w),
        .h = @intFromFloat(h),
    };
}
