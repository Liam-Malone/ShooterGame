const std = @import("std");
const entities = @import("entities.zig");
const math = @import("math.zig");
const Hitbox = entities.Hitbox;
const c = @import("c.zig");

const print = std.debug.print;

const FONT_FILE = @embedFile("DejaVuSans.ttf");
const PIXEL_BUFFER = 1;
const TILE_WIDTH = 80;
const TILE_HEIGHT = 80;

pub const Color = enum(u32) {
    white = 0xFFFFFFFF,
    purple = 0x7BF967AA,
    red = 0xFC1A17CC,
    dark_gray = 0x181818FF,
    blue = 0x0000CCFF,
    green = 0x00AA00FF,
    dirt = 0x3C2414AA,
    wood = 0x22160B88,
    stone = 0x7F7F98AA,
    leaves = 0x00FF0000,
    void = 0xFF00FFFF,

    pub fn make_sdl_color(col: Color) c.SDL_Color {
        var color = @intFromEnum(col);
        const r: u8 = @truncate((color >> (3 * 8)) & 0xFF);
        const g: u8 = @truncate((color >> (2 * 8)) & 0xFF);
        const b: u8 = @truncate((color >> (1 * 8)) & 0xFF);
        const a: u8 = @truncate((color >> (0 * 8)) & 0xFF);

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
    void = 0,
    grass = 1,
    stone = 2,
    water = 3,
    wood = 4,
    dirt = 5,
    leaves = 6,
};

pub const TextureMap = struct {
    textures: []?*c.SDL_Texture,

    pub fn init(allocator: std.mem.Allocator, arena_allocator: std.mem.Allocator, renderer: *c.SDL_Renderer, path: [:0]u8) !TextureMap {
        var tex_list = std.ArrayList(?*c.SDL_Texture).init(allocator);

        try tex_list.append(try load_tex(arena_allocator, renderer, path, TileID.void));
        try tex_list.append(try load_tex(arena_allocator, renderer, path, TileID.grass));
        try tex_list.append(try load_tex(arena_allocator, renderer, path, TileID.stone));
        try tex_list.append(try load_tex(arena_allocator, renderer, path, TileID.water));
        try tex_list.append(try load_tex(arena_allocator, renderer, path, TileID.wood));
        try tex_list.append(try load_tex(arena_allocator, renderer, path, TileID.dirt));
        try tex_list.append(try load_tex(arena_allocator, renderer, path, TileID.leaves));

        return TextureMap{
            .textures = try tex_list.toOwnedSlice(),
        };
    }
    pub fn deinit(self: *TextureMap) void {
        for (self.textures) |tex| {
            c.SDL_DestroyTexture(tex);
        }
    }
    // arena alloc_time
    pub fn load_tex(arena_allocator: std.mem.Allocator, renderer: *c.SDL_Renderer, path: [:0]u8, tile_id: TileID) !?*c.SDL_Texture {
        var tex: ?*c.SDL_Texture = null;
        var default_tex_path = try std.fmt.allocPrint(arena_allocator, "{s}{s}", .{ path, "no_tex.png" });
        var i: usize = 0;
        const tmp_def = try arena_allocator.alloc(u8, default_tex_path.len + 1);
        tmp_def[default_tex_path.len] = 0;
        while (i < default_tex_path.len) {
            tmp_def[i] = default_tex_path[i];
            i += 1;
        }
        const default_path = tmp_def[0..default_tex_path.len :0];

        var tex_path: []u8 = undefined;
        switch (tile_id) {
            .void => tex_path = try std.fmt.allocPrint(arena_allocator, "{s}{s}", .{ path, "no_tex.png" }),
            .grass => tex_path = try std.fmt.allocPrint(arena_allocator, "{s}{s}", .{ path, "grass-tex.png" }),
            .stone => tex_path = try std.fmt.allocPrint(arena_allocator, "{s}{s}", .{ path, "basic-stone.png" }),
            .water => tex_path = try std.fmt.allocPrint(arena_allocator, "{s}{s}", .{ path, "water-tex.png" }),
            .dirt => tex_path = try std.fmt.allocPrint(arena_allocator, "{s}{s}", .{ path, "dirt-tex.png" }),
            .wood, .leaves => {
                std.debug.print("*** TODO: add texture for {any} *** \n", .{tile_id});
                tex_path = default_tex_path;
            },
        }

        var tmp = try arena_allocator.alloc(u8, tex_path.len + 1);
        i = 0;
        while (i < tex_path.len) {
            tmp[i] = tex_path[i];
            i += 1;
        }
        tmp[tex_path.len] = 0;
        const tmp_str = tmp[0..tex_path.len :0];

        tex = c.IMG_LoadTexture(renderer, @ptrCast(tmp_str)) orelse c.IMG_LoadTexture(renderer, default_path);
        return tex;
    }
};

const Tile = struct {
    w: i32,
    h: i32,
    x: i32,
    y: i32,
    id: TileID,
    tex: ?*c.SDL_Texture,
    tex_map: *TextureMap,
    is_assigned: bool = false,

    pub fn init(id: u32, x: u32, y: u32, tex_map: *TextureMap, w: u32, h: u32, assigned: bool) Tile {
        const tile = switch (id) {
            0 => TileID.void,
            1 => TileID.grass,
            2 => TileID.stone,
            3 => TileID.water,
            4 => TileID.dirt,
            else => TileID.void,
        };

        if (!assigned) std.debug.print("hmmm: ({d}, {d})\n", .{ x, y });
        return Tile{
            .w = @intCast(w),
            .h = @intCast(h),
            .x = @intCast(x * w),
            .y = @intCast(y * h),
            .id = tile,
            .tex = tex_map.*.textures[@intFromEnum(tile)],
            .tex_map = tex_map,
            .is_assigned = assigned,
        };
    }
    pub fn update(self: *Tile, id: TileID) void {
        self.id = id;
        self.tex = self.tex_map.*.textures[@intFromEnum(id)];
        std.debug.print("new tex w id: {any}\n", .{id});
    }

    pub fn render(self: *Tile, renderer: *c.SDL_Renderer, vp: *Viewport) void {
        if (vp.can_see(self.x, self.y, self.w, self.h)) {
            const rect = c.SDL_Rect{
                .x = @intCast(self.x - vp.x),
                .y = @intCast(self.y - vp.y),
                .w = @intCast(self.w),
                .h = @intCast(self.h),
            };
            if (!self.is_assigned) {
                set_render_color(renderer, Color.make_sdl_color(self.get_color()));
                _ = c.SDL_RenderFillRect(renderer, &rect);
                return;
            }
            if (self.tex) |tex| _ = c.SDL_RenderCopy(renderer, tex, null, &rect);
        }
    }

    pub fn get_color(self: *Tile) Color {
        var col: Color = undefined;
        switch (self.id) {
            TileID.grass => col = Color.green,
            TileID.dirt => col = Color.dirt,
            TileID.wood => col = Color.wood,
            TileID.stone => col = Color.stone,
            TileID.leaves => col = Color.leaves,
            else => col = Color.void,
        }
        return col;
    }
};
pub const Tilemap = struct {
    tile_list: [][]Tile,
    filename: []const u8,

    pub fn init(filepath: []const u8, allocator: std.mem.Allocator, tex_map: *TextureMap, tile_w: u32, tile_h: u32, world_width: u32, world_height: u32) !Tilemap {
        print("\ntrying path: {s}\n", .{filepath});
        var tile_list = try load_from_file(filepath, allocator, tex_map, tile_w, tile_h, world_width, world_height);
        var tile_count: usize = 0;
        for (tile_list) |tile| {
            _ = tile;
            tile_count += 1;
        }
        return Tilemap{
            .tile_list = tile_list,
            .filename = filepath,
        };
    }

    pub fn deinit(self: *Tilemap) void {
        _ = self;
    }

    //**********************************//
    //       MAP IMPORT FROM FILE       //
    //  ------------------------------  //
    //       *** ==> TODO <== ***       //
    //                                  //
    //  enable allocation of correctly  //
    //  sized buffers depending on      //
    //  the size of the map file        //
    //                                  //
    //  ------------------------------  //
    //       *** ==> TODO <== ***       //
    //                                  //
    //  enable passing of new files     //
    //  open read-only? create if fail? //
    //                                  //
    //**********************************//
    fn load_from_file(filepath: []const u8, allocator: std.mem.Allocator, tex_map: *TextureMap, tile_w: u32, tile_h: u32, world_width: u32, world_height: u32) ![][]Tile {
        const arr_len = (world_width / tile_w) * (world_height / tile_h);
        var map = std.ArrayList([]Tile).init(allocator); // caller needs to free on return
        const data = try std.fs.cwd().readFileAlloc(allocator, filepath, 855000);
        defer allocator.free(data);

        var iter_lines = std.mem.split(u8, data, "\n");
        var counter: u32 = 0;
        var y: u32 = 0;
        var is_first = true;
        while (iter_lines.next()) |line| {
            if (line.len < 1 and is_first) {
                const id = 0;
                while (y < world_height / tile_h) {
                    var x: u32 = 0;
                    var col = std.ArrayList(Tile).init(allocator);
                    while (x < world_width / tile_w) {
                        try col.append(Tile.init(id, x, y, tex_map, tile_w, tile_h, true));
                        counter += 1;
                        x += 1;
                    }
                    y += 1;
                    try map.append(try col.toOwnedSlice());
                }
            } else {
                var x: u32 = 0;
                var col = std.ArrayList(Tile).init(allocator);
                var iter_col = std.mem.split(u8, line, " ");
                while (iter_col.next()) |val| {
                    if (val.len > 0) {
                        const id = try std.fmt.parseInt(u32, val, 10);
                        try col.append(Tile.init(id, x, y, tex_map, tile_w, tile_h, true));
                        counter += 1;
                        x += 1;
                    }
                }
                y += 1;
                try map.append(try col.toOwnedSlice());
            }
        }
        std.debug.print("counted\texpected\n{d}\t{d}\n", .{ counter, arr_len });
        return try map.toOwnedSlice();
    }
    pub fn edit_tile(self: *Tilemap, id: TileID, x: u32, y: u32) void {
        if (y >= self.tile_list.len or x >= self.tile_list[0].len) return;
        if (!self.tile_list[y][x].is_assigned) {
            std.debug.print("edit new item []\n", .{});
            self.tile_list[y][x].x = @as(i32, @intCast(x)) * self.tile_list[y][x].w;
            self.tile_list[y][x].y = @as(i32, @intCast(y)) * self.tile_list[y][x].h;
            self.tile_list[y][x].is_assigned = true;
            self.tile_list[y][x].update(id);
            return;
        } else {
            if (self.tile_list[y][x].id == id) {
                print("same id: {any}\n", .{id});
                return;
            } else {
                std.debug.print("edit item []\n", .{});
                self.tile_list[y][x].update(id);
                return;
            }
        }
    }

    //**********************************//
    //           FILE EXPORT            //
    // -------------------------------- //
    //       *** ==> TODO <== ***       //
    // add check for file existence and //
    // create file if it does not exist //
    //**********************************//
    pub fn export_to_file(self: *Tilemap, output_file: []const u8, allocator: std.mem.Allocator) !void {
        var file = std.fs.cwd().openFile(
            output_file,
            .{ .mode = std.fs.File.OpenMode.write_only },
        ) catch try std.fs.cwd().createFile(output_file, .{});
        defer file.close();
        for (self.tile_list, 0..) |col, y| {
            for (col, 0..) |tile, x| {
                var tile_string: ?[]const u8 = null;
                if (x + 1 == self.tile_list[y].len) {
                    tile_string = try std.fmt.allocPrint(allocator, "{d}", .{@intFromEnum(tile.id)});
                } else {
                    tile_string = try std.fmt.allocPrint(allocator, "{d} ", .{@intFromEnum(tile.id)});
                }

                if (tile_string) |ts| {
                    defer allocator.free(ts);
                    _ = try file.write(ts);
                }
            }
            _ = try file.write("\n");
        }
        const stdout = std.io.getStdOut().writer();
        try stdout.print("File export completed\n", .{});
    }

    pub fn save(self: *Tilemap, allocator: std.mem.Allocator) !void {
        try self.export_to_file(self.filename, allocator);
    }

    pub fn render(self: *Tilemap, renderer: *c.SDL_Renderer, vp: *Viewport, window: Window) void {
        _ = window;
        for (self.tile_list, 0..) |col, i| {
            for (col, 0..) |tile, j| {
                _ = tile;
                self.tile_list[i][j].render(renderer, vp);
            }
        }
    }

    // debug purposes
    fn print_map(map: []Tile) !void {
        for (map) |tile| {
            print("{any} ", .{tile});
            print("\n", .{});
        }
    }
};

pub const Viewport = struct {
    x: i32,
    max_x: usize,
    y: i32,
    max_y: usize,
    w: i32,
    h: i32,
    rect: c.SDL_Rect,
    dx: i32 = 0,
    dy: i32 = 0,

    pub fn init(x: i32, y: i32, w: u32, h: u32, world_width: usize, world_height: usize) Viewport {
        return Viewport{
            .x = x,
            .max_x = world_width,
            .y = y,
            .max_y = world_height - @as(usize, h),
            .w = @intCast(w),
            .h = @intCast(h),
            .rect = c.SDL_Rect{
                .x = @intCast(x),
                .y = @intCast(y),
                .w = @intCast(w),
                .h = @intCast(h),
            },
        };
    }
    pub fn update(self: *Viewport) void {
        if (self.x + self.dx > 0 and self.x + self.w + self.dx < self.max_x) self.x += self.dx;
        if (self.y + self.dy > 0 and self.y + self.dy < self.max_y) self.y += self.dy;

        self.dy += if (self.dy > 0) -1 else if (self.dy < 0) 1 else 0;
        self.dx += if (self.dx > 0) -1 else if (self.dx < 0) 1 else 0;
        self.rect = c.SDL_Rect{
            .x = @as(c_int, self.x),
            .y = @as(c_int, self.y),
            .w = @as(c_int, self.w),
            .h = @as(c_int, self.h),
        };
    }

    // set dx and dy to glide to center player
    pub fn move(self: *Viewport, player_x: f32, player_y: f32, win_width: u32, win_height: u32) void {
        self.w = @intCast(win_width);
        self.h = @intCast(win_height);
        const diffx: i32 = @as(i32, @intFromFloat(player_x)) - (self.x + @divTrunc(self.w, 2));
        self.dx = @divTrunc(diffx, 2);
        const diffy: i32 = @as(i32, @intFromFloat(player_y)) - (self.y + @divTrunc(self.h, 2));
        self.dy = @divTrunc(diffy, 2);
    }

    pub fn can_see(self: *Viewport, x: i32, y: i32, w: i32, h: i32) bool {
        if ((x + w > self.x or x > self.x + self.w) and (y + h > self.y or y < self.y + self.h)) {
            return true;
        } else {
            return false;
        }
    }
};

pub const Sprite = struct {
    img_tex: ?*c.SDL_Texture,
    flipped: bool = false,

    pub fn init(renderer: *c.SDL_Renderer, path: [*c]const u8) Sprite {
        const tex = c.IMG_LoadTexture(renderer, path);

        return Sprite{
            .img_tex = tex,
        };
    }
    pub fn deinit(self: *Sprite) void {
        defer c.SDL_DestroyTexture(self.img_tex);
    }
    pub fn flip(self: *Sprite) void {
        self.flipped = true;
    }
    pub fn unflip(self: *Sprite) void {
        self.flipped = false;
    }

    pub fn render(self: *Sprite, renderer: *c.SDL_Renderer, rect: c.SDL_Rect, vp: *Viewport) void {
        // not final
        //if (rect.x + rect.w - vp.x > vp.x or rect.x - vp.x < vp.x + vp.w) {
        if (vp.can_see(rect.x, rect.y, rect.w, rect.h)) {
            const render_rect = c.SDL_Rect{
                .x = (rect.x - vp.x),
                .y = (rect.y - vp.y),
                .w = rect.w + 60,
                .h = rect.h + 20,
            };
            //_ = c.SDL_RenderCopy(renderer, self.img_tex, null, &render_rect);
            if (self.flipped) {
                _ = c.SDL_RenderCopyEx(renderer, self.img_tex, null, &render_rect, 0, null, c.SDL_FLIP_HORIZONTAL);
            } else _ = c.SDL_RenderCopyEx(renderer, self.img_tex, null, &render_rect, 0, null, c.SDL_FLIP_NONE);
        }
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
pub fn render_hitbox(renderer: *c.SDL_Renderer, hb: Hitbox, vp: *Viewport) void {
    if (vp.can_see(@intFromFloat(hb.x), @intFromFloat(hb.y), @intFromFloat(hb.w), @intFromFloat(hb.h))) {
        const rect = c.SDL_Rect{
            .x = @as(i32, @intFromFloat(hb.x)) - vp.x,
            .y = @as(i32, @intFromFloat(hb.y)) - vp.y,
            .w = @as(i32, @intFromFloat(hb.w)),
            .h = @as(i32, @intFromFloat(hb.h)),
        };
        set_render_color(renderer, Color.make_sdl_color(hb.color));
        _ = c.SDL_RenderDrawRect(renderer, &rect);
    }
}

pub fn make_sdl_rect(x: f32, y: f32, w: f32, h: f32) c.SDL_Rect {
    return c.SDL_Rect{
        .x = @intFromFloat(x),
        .y = @intFromFloat(y),
        .w = @intFromFloat(w),
        .h = @intFromFloat(h),
    };
}
