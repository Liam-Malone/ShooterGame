const std = @import("std");
const graphics = @import("graphics.zig");
const sdl = @import("sdl.zig");

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

pub const ButtonID = enum {
    SelectWater,
    SelectGrass,
    SelectDirt,
    SelectStone,
};

pub const Button = struct {
    x: u32,
    y: u32,
    w: u32,
    h: u32,
    color: graphics.Color,
    rect: sdl.SDL_Rect,
    id: ButtonID,

    pub fn init(x: u32, y: u32, w: u32, h: u32, color: graphics.Color, id: ButtonID) Button {
        return Button{
            .x = x,
            .y = y,
            .w = w,
            .h = h,
            .color = color,
            .id = id,
            .rect = sdl.SDL_Rect{
                .x = @intCast(x),
                .y = @intCast(y),
                .w = @intCast(w),
                .h = @intCast(h),
            },
        };
    }
    pub fn click(self: *const Button, x: u32, y: u32) ?ButtonID {
        if (x >= self.x and x <= self.x + self.w and y >= self.y and y <= self.y + self.h) {
            return self.id;
        } else {
            return null;
        }
    }

    pub fn render(self: *const Button, renderer: *sdl.SDL_Renderer) void {
        graphics.set_render_color(renderer, graphics.Color.make_sdl_color(self.color));
        _ = sdl.SDL_RenderFillRect(renderer, &self.rect);
    }
};
