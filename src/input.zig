const std = @import("std");
const entities = @import("entities.zig");
const graphics = @import("graphics.zig");
const Window = graphics.Window;
const SoundEffect = @import("audio.zig").SoundEffect;
const Player = entities.Player;
const Bullet = entities.Bullet;
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
    @cInclude("SDL2/SDL_image.h");
});

pub fn handle_player_event(window: *Window, event: c.SDL_Event, player: *Player, bullets: *[10]Bullet) void {
    switch (event.type) {
        c.SDL_KEYDOWN => switch (event.key.keysym.sym) {
            'w' => {
                player.dy = player.move_speed * -1;
            },
            'a' => {
                player.dx = player.move_speed * -1;
                player.sprite.flip();
            },
            's' => {
                player.dy = player.move_speed;
            },
            'd' => {
                player.dx = player.move_speed;
                player.sprite.unflip();
            },
            'h' => {
                player.toggle_hitbox_vis();
            },
            'f' => {
                window.toggle_fullscreen();
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
                const startx = player.x + (player.hb.w / 2);
                const starty = player.y + (player.hb.h / 4);
                for (bullets, 0..) |_, i| {
                    if (!bullets[i].fired) {
                        const dx = (@as(f32, @floatFromInt(event.button.x)) - startx) / 10;
                        const dy = (@as(f32, @floatFromInt(event.button.y)) - starty) / 10;
                        bullets[i].fire(startx, starty, dx, dy);
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
