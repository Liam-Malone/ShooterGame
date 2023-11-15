const std = @import("std");
const graphics = @import("graphics.zig");
const c = @import("c.zig");

const Tile = graphics.Tile;

pub const Overlay = struct {
    hidden: bool,

    pub const Button = struct {
        x: u32,
        y: u32,
        w: u32,
        h: u32,
        rect: c.SDL_Rect,
        func: fn () void,

        pub fn init(comptime x: u32, comptime y: u32, comptime w: u32, comptime h: u32, comptime function: anytype) Button {
            return Button{
                .x = x,
                .y = y,
                .w = w,
                .h = h,
                .rect = c.SDL_Rect{
                    .x = @intCast(x),
                    .y = @intCast(y),
                    .w = @intCast(w),
                    .h = @intCast(h),
                },
                .func = function,
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
            _ = c.SDL_RenderFillRect(renderer, &self.rect);
        }
    };
};
