const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
});
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

pub const Player = struct {
    x: f32,
    y: f32,
    dx: f32,
    dy: f32,
};
pub const Bullet = struct {
    x: f32,
    y: f32,
    dx: f32,
    dy: f32,
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
};

fn abs(num: f32) f32 {
    switch (num > 0) {
        true => return num,
        false => return (num * -1),
    }
}
