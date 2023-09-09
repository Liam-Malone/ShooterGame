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
    dx: f32 = 0,
    dy: f32 = 0,
    move_speed: f32 = 2,
    hitpoints: u8 = 10,
    hb: Hitbox,
    hb_visibility: Visibility = Visibility.Invisible,

    pub fn init(x: f32, y: f32, hp: u8) Player {
        return Player{
            .x = x,
            .y = y,
            .hitpoints = hp,
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
    pub fn toggle_hitbox_vis(self: *Player) void {
        switch (self.hb_visibility) {
            Visibility.Visible => {
                self.hb_visibility = Visibility.Invisible;
            },
            Visibility.Invisible => {
                self.hb_visibility = Visibility.Visible;
            },
        }
    }
};
pub const Bullet = struct {
    id: u8,
    x: f32 = 0,
    y: f32 = 0,
    dx: f32 = 0,
    dy: f32 = 0,
    fired: bool = false,
    hb: Hitbox,
    hb_visibility: Visibility = Visibility.Invisible,

    pub fn init(id: u8) Bullet {
        return Bullet{
            .id = id,
            .hb = Hitbox{
                .x = 0,
                .y = 0,
                .w = 5,
                .h = 5,
            },
        };
    }
    pub fn update(self: *Bullet) void {
        self.x += self.dx;
        self.y += self.dy;
        self.hb = Hitbox{
            .x = self.x,
            .y = self.y,
            .w = 5,
            .h = 5,
        };
    }
    pub fn fire(self: *Bullet, x: f32, y: f32, dx: f32, dy: f32) void {
        self.fired = true;
        self.x = x;
        self.y = y;
        self.dx = dx;
        self.dy = dy;
        self.hb_visibility = Visibility.Visible;
        self.hb = Hitbox{
            .x = self.x,
            .y = self.y,
            .w = 5,
            .h = 5,
        };
    }
    pub fn reset(self: *Bullet) void {
        self.fired = false;
        self.x = 0;
        self.y = 0;
        self.dx = 0;
        self.dy = 0;
        self.hb_visibility = Visibility.Invisible;
        self.hb = Hitbox{
            .x = self.x,
            .y = self.y,
            .w = 5,
            .h = 5,
        };
    }
};
