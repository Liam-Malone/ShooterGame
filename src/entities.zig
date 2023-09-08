const std = @import("std");
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
    hitpoints: u8,
    hb: Hitbox,

    pub fn init(x: f32, y: f32, hp: u8, hb: Hitbox) Player {
        return Player{
            .x = x,
            .y = y,
            .dx = 0,
            .dy = 0,
            .hitpoints = hp,
            .hb = hb,
        };
    }
};
pub const Bullet = struct {
    x: f32,
    y: f32,
    dx: f32,
    dy: f32,
};
