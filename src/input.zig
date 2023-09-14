const std = @import("std");
const entities = @import("entities.zig");
const SoundEffect = @import("audio.zig").SoundEffect;
const Player = entities.Player;
const Bullet = entities.Bullet;
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
});

pub fn handle_player_event(event: c.SDL_Event, player: *Player, bullets: *[10]Bullet, footstep: *SoundEffect) void {
    switch (event.type) {
        c.SDL_KEYDOWN => switch (event.key.keysym.sym) {
            'w' => {
                player.dy = player.move_speed * -1;
                footstep.play();
            },
            'a' => {
                player.dx = player.move_speed * -1;
                footstep.play();
            },
            's' => {
                player.dy = player.move_speed;
                footstep.play();
            },
            'd' => {
                player.dx = player.move_speed;
                footstep.play();
            },
            'h' => {
                player.toggle_hitbox_vis();
                footstep.play();
            },
            else => {},
        },
        c.SDL_KEYUP => switch (event.key.keysym.sym) {
            'w' => {
                if (player.dy == player.move_speed * -1) {
                    player.dy = 0;
                }
            },
            'a' => {
                if (player.dx == player.move_speed * -1) {
                    player.dx = 0;
                }
            },
            's' => {
                if (player.dy == player.move_speed) {
                    player.dy = 0;
                }
            },
            'd' => {
                if (player.dx == player.move_speed) {
                    player.dx = 0;
                }
            },
            else => {},
        },
        c.SDL_MOUSEBUTTONDOWN => switch (event.button.button) {
            c.SDL_BUTTON_LEFT => {
                // implement time delay
                for (bullets, 0..) |_, i| {
                    if (!bullets[i].fired) {
                        const dx = (@as(f32, @floatFromInt(event.button.x)) - player.x) / 10;
                        const dy = (@as(f32, @floatFromInt(event.button.y)) - player.y) / 10;
                        bullets[i].fire(player.x, player.y, dx, dy);
                        std.debug.print("firing\n", .{});
                        return;
                    }
                }
                std.debug.print("no bullets available\n", .{});
                return;
            },
            else => {},
        },
        else => {},
    }
}
