const std = @import("std");

pub const Visibility = enum {
    Visible,
    Invisible,
};

pub const Hitbox = struct {
    x: f32,
    y: f32,
    w: f32,
    h: f32,
};

pub const Player = struct {
    x: f32,
    y: f32,
    dx: f32,
    dy: f32,
    move_speed: f32 = 2,
    hitpoints: u8,
    hb: Hitbox,
    hb_visibility: Visibility,

    pub fn init(x: f32, y: f32, hp: u8) Player {
        return Player{
            .x = x,
            .y = y,
            .dx = 0,
            .dy = 0,
            .hitpoints = hp,
            .hb_visibility = Visibility.Invisible,
            .hb = Hitbox{
                .x = x,
                .y = y,
                .w = 20,
                .h = 60,
            },
        };
    }
    pub fn update(self: *Player) void {
        self.x += self.dx;
        self.y += self.dy;
        self.hb = Hitbox{
            .x = self.x,
            .y = self.y,
            .w = 20,
            .h = 60,
        };
    }
};
pub const Bullet = struct {
    x: f32,
    y: f32,
    dx: f32,
    dy: f32,
};
