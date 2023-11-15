const std = @import("std");
const graphics = @import("graphics.zig");
const c = @import("c.zig");

const Tile = graphics.Tile;

pub const Toolbar = struct {
    color: graphics.Color = graphics.Color.stone,
    buttons: []Button,
    x: u32,
    y: u32,
    w: u32,
    h: u32,

    pub fn init(buttons: []Button, color: graphics.Color, x: u32, y: u32) Toolbar {
        const w = 40;
        const h = buttons[0].h * buttons.len + 8 * buttons.len;
        return Toolbar{
            .buttons = buttons,
            .color = color,
            .x = x,
            .y = y,
            .w = w,
            .h = h,
        };
    }

    pub fn add_button(self: *Toolbar, allocator: std.mem.Allocator, button: Button) void {
        const new_arr = allocator.alloc(Button, self.buttons.len + 1);
        new_arr[new_arr.len - 1] = button;
        for (self.buttons, 0..) |b, i| {
            new_arr[i] = b;
        }
    }
};

pub const Button = struct {
    x: u32,
    y: u32,
    w: u32,
    h: u32,
    color: graphics.Color,
    func: fn () void,
    rect: c.SDL_Rect,

    pub fn init(comptime x: u32, comptime y: u32, comptime w: u32, comptime h: u32, comptime color: graphics.Color, comptime function: anytype) Button {
        return Button{
            .x = x,
            .y = y,
            .w = w,
            .h = h,
            .color = color,
            .func = function,
            .rect = c.SDL_Rect{
                .x = @intCast(x),
                .y = @intCast(y),
                .w = @intCast(w),
                .h = @intCast(h),
            },
        };
    }
    pub fn click(comptime self: *const Button, x: u32, y: u32) bool {
        if (x >= self.x and x <= self.x + self.w and y >= self.y and y <= self.y + self.h) {
            self.func();
            return true;
        } else {
            return false;
        }
    }

    pub fn render(comptime self: *const Button, renderer: *c.SDL_Renderer) void {
        // render tile
        graphics.set_render_color(renderer, graphics.Color.make_sdl_color(self.color));
        _ = c.SDL_RenderFillRect(renderer, &self.rect);
    }
};
