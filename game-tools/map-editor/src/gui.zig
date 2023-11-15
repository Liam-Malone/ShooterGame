const std = @import("std");
const graphics = @import("graphics.zig");
const c = @import("c.zig");

const overlay = struct {
    hidden: bool,

    fn button(comptime T: anyopaque, comptime Fn: type) type {
        _ = Fn;
        _ = T;
        return struct {};
    }
    const Button = struct {
        x: u32,
        y: u32,
        w: u32,
        h: u32,
        func: anyopaque,

        pub fn init(x: u32, y: u32, w: u32, h: u32, function: anyopaque) Button {
            return Button{
                .x = x,
                .y = y,
                .w = w,
                .h = h,
                .func = function,
            };
        }
        pub fn click(self: *Button, x: u32, y: u32) bool {
            if (x >= self.x and x <= self.x + self.w and y >= self.y and y <= self.y + self.h) {
                self.func();
                return true;
            } else {
                return false;
            }
        }
    };
};
