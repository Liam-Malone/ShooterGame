const std = @import("std");
const Player = @import("entities.zig").Player;
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
});

pub fn handle_player_event(event: c.SDL_Event, player: *Player) void {
    switch (event.type) {
        c.SDL_KEYDOWN => switch (event.key.keysym.sym) {
            'w' => {
                player.dy = player.move_speed * -1;
            },
            'a' => {
                player.dx = player.move_speed * -1;
            },
            's' => {
                player.dy = player.move_speed;
            },
            'd' => {
                player.dx = player.move_speed;
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
        else => {},
    }
}
