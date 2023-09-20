const std = @import("std");
const entities = @import("entities.zig");
const math = @import("math.zig");
const Hitbox = entities.Hitbox;
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
    @cInclude("SDL2/SDL_image.h");
});

const print = std.debug.print;

const FONT_FILE = @embedFile("DejaVuSans.ttf");
const PIXEL_BUFFER = 1;

pub const Color = enum(u32) {
    white = 0xFFFFFFFF,
    purple = 0x7BF967AA,
    red = 0xFC1A17CC,
    dark_gray = 0xFF181818,

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
    pub fn update(self: *Viewport) void {
        self.x += self.dx;
        self.y += self.dy;
        self.rect = c.SDL_Rect{
            .x = @as(c_int, self.x),
            .y = @as(c_int, self.y),
            .w = @as(c_int, self.w),
            .h = @as(c_int, self.h),
        };
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

    pub fn render(self: *Sprite, renderer: *c.SDL_Renderer, rect: c.SDL_Rect, vp: Viewport) void {
        // not final
        if (rect.x + rect.w - vp.x > vp.x or rect.x - vp.x < vp.x + vp.w) {
            const render_rect = c.SDL_Rect{
                .x = (rect.x - vp.x),
                .y = (rect.y - vp.y),
                .w = rect.w + 20,
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
pub fn render_hitbox(renderer: *c.SDL_Renderer, hb: Hitbox) void {
    const rect = c.SDL_Rect{
        .x = @intFromFloat(hb.x),
        .y = @intFromFloat(hb.y),
        .w = @intFromFloat(hb.w),
        .h = @intFromFloat(hb.h),
    };
    set_render_color(renderer, Color.make_sdl_color(hb.color));
    _ = c.SDL_RenderDrawRect(renderer, &rect);
}

pub fn make_sdl_rect(x: f32, y: f32, w: f32, h: f32) c.SDL_Rect {
    return c.SDL_Rect{
        .x = @intFromFloat(x),
        .y = @intFromFloat(y),
        .w = @intFromFloat(w),
        .h = @intFromFloat(h),
    };
}
