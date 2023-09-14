const std = @import("std");
const graphics = @import("graphics.zig");
const audio = @import("audio.zig");
const math = @import("math.zig");

const SoundEffect = audio.SoundEffect;
const Vec2 = math.Vec2;

pub const Visibility = enum {
    Visible,
    Invisible,
};

pub const Hitbox = struct {
    x: f32,
    y: f32,
    w: f32,
    h: f32,
    color: graphics.Color,
};

pub const Player = struct {
    x: f32,
    y: f32,
    dx: f32 = 0,
    dy: f32 = 0,
    move_speed: f32 = 1,
    hitpoints: u8 = 10,
    hb: Hitbox,
    footsteps: SoundEffect,
    hb_visibility: Visibility = Visibility.Visible,

    pub fn init(x: f32, y: f32, hp: u8, footsteps: SoundEffect) Player {
        return Player{
            .x = x,
            .y = y,
            .hitpoints = hp,
            .footsteps = footsteps,
            .hb = Hitbox{
                .x = x,
                .y = y,
                .w = 20,
                .h = 60,
                .color = graphics.Color.purple,
            },
        };
    }
    pub fn update(self: *Player) void {
        self.x += self.dx;
        self.y += self.dy;
        if (self.dx != 0 or self.dy != 0) self.footsteps.play();
        self.hb = Hitbox{
            .x = self.x,
            .y = self.y,
            .w = 20,
            .h = 60,
            .color = graphics.Color.purple,
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

pub const StandardEnemy = struct {
    x: f32,
    y: f32,
    dx: f32 = 2,
    dy: f32 = 1,
    speed: f32 = 1,
    hitpoints: u8 = 10,
    hb: Hitbox,
    hb_visibility: Visibility = Visibility.Visible,

    pub fn init(x: f32, y: f32) StandardEnemy {
        return StandardEnemy{
            .x = x,
            .y = y,
            .hb = Hitbox{
                .x = x,
                .y = y,
                .w = 10,
                .h = 30,
                .color = graphics.Color.red,
            },
        };
    }

    pub fn update(self: *StandardEnemy) void {
        self.x += self.dx;
        self.y += self.dy;
        self.hb = Hitbox{
            .x = self.x,
            .y = self.y,
            .w = 10,
            .h = 30,
            .color = graphics.Color.red,
        };
    }

    pub fn hit(self: *StandardEnemy, dmg: u8) void {
        self.hitpoints -= dmg;
    }

    pub fn destroy(self: *StandardEnemy) bool {
        if (self.hitpoints <= 0) {
            self.x = 50;
            self.y = 80;
            self.dx *= -1;
            self.dy *= -1;
            self.hitpoints = 10;
            //self.hb_visibility = Visibility.Invisible;
            return true;
        }
        return false;
    }
};

pub const Bullet = struct {
    id: u8,
    sound: SoundEffect,
    speed: f32 = 10,
    x: f32 = 0,
    y: f32 = 0,
    dx: f32 = 0,
    dy: f32 = 0,
    fired: bool = false,
    hb: Hitbox,
    hb_visibility: Visibility = Visibility.Invisible,
    vec: Vec2 = Vec2{
        .x = 0,
        .y = 0,
        .mag = 0,
    },

    pub fn init(id: u8, gunshot: SoundEffect) Bullet {
        return Bullet{
            .id = id,
            .sound = gunshot,
            .hb = Hitbox{
                .x = 0,
                .y = 0,
                .w = 5,
                .h = 5,
                .color = graphics.Color.white,
            },
        };
    }
    pub fn update(self: *Bullet) void {
        self.x += self.vec.x;
        self.y += self.vec.y;
        self.hb = Hitbox{
            .x = self.x,
            .y = self.y,
            .w = 5,
            .h = 5,
            .color = graphics.Color.white,
        };
    }
    pub fn fire(self: *Bullet, x: f32, y: f32, targ_x: f32, targ_y: f32) void {
        self.sound.play();
        self.fired = true;
        self.x = x;
        self.y = y;
        self.hb = Hitbox{
            .x = self.x,
            .y = self.y,
            .w = 5,
            .h = 5,
            .color = graphics.Color.white,
        };
        //todo:
        //  - set bullet dx and dy to give direction, not speed
        //  implement new methods at bottom

        self.vec = Vec2{
            .x = targ_x,
            .y = targ_y,
            .mag = Vec2.mag(targ_x, targ_y),
        };
        self.vec.adjust(self.speed);

        self.hb_visibility = Visibility.Visible;
        self.hb = Hitbox{
            .x = self.x,
            .y = self.y,
            .w = 5,
            .h = 5,
            .color = graphics.Color.white,
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
            .color = graphics.Color.white,
        };
    }
};

fn normalize_speed(speed: f32, x: f32, y: f32) Vec2 {
    const mag = std.math.sqrt((std.math.pow(f32, x, 2) + std.math.pow(f32, y, 2)));
    var newx: f32 = undefined;
    var newy: f32 = undefined;

    if (mag != speed) {
        const r = speed / mag;
        newx = (x / mag) * r;
        newy = (y / mag) * r;
    } else {
        newx = x;
        newy = y;
    }

    return Vec2{
        .x = newx,
        .y = newy,
    };
}
