const std = @import("std");
const graphics = @import("graphics.zig");
const entities = @import("entities.zig");
const Window = graphics.Window;
const Color = graphics.Color;
const Player = entities.Player;
const Bullet = entities.Bullet;
const Hitbox = entities.Hitbox;
const Visibility = entities.Visibility;
const handle_player_event = @import("input.zig").handle_player_event;

const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
});

const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 600;
const FPS = 60;
const BACKGROUND_COLOR = Color.dark_gray;
const BULLET_COUNT = 10;

fn set_render_color(renderer: *c.SDL_Renderer, col: c.SDL_Color) void {
    _ = c.SDL_SetRenderDrawColor(renderer, col.r, col.g, col.b, col.a);
}

fn create_bullets() [BULLET_COUNT]Bullet {
    var bullets: [BULLET_COUNT]Bullet = undefined;
    for (0..BULLET_COUNT) |index| {
        bullets[index] = Bullet.init(BULLET_COUNT);
    }
    return bullets;
}

fn is_offscreen(x: f32, y: f32) bool {
    if (x < 0 or x > WINDOW_WIDTH) {
        return true;
    } else if (y < 0 or y > WINDOW_HEIGHT) {
        return true;
    }
    return false;
}

var quit = false;
var pause = false;
pub fn main() !void {
    var window: Window = try Window.init("ShooterGame", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);
    defer window.deinit();

    var player: Player = Player.init(300, 300, 20);
    var bullets = create_bullets();
    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            handle_player_event(event, &player, &bullets);
            switch (event.type) {
                c.SDL_QUIT => {
                    quit = true;
                },
                c.SDL_KEYDOWN => switch (event.key.keysym.sym) {
                    'q' => {
                        quit = true;
                    },
                    ' ' => {
                        pause = !pause;
                    },
                    else => {},
                },
                else => {},
            }
        }

        set_render_color(window.renderer, Color.make_sdl_color(BACKGROUND_COLOR));
        _ = c.SDL_RenderClear(window.renderer);

        player.update();
        switch (player.hb_visibility) {
            Visibility.Visible => {
                graphics.render_hitbox(window.renderer, player.hb);
            },
            Visibility.Invisible => {},
        }
        for (bullets, 0..) |_, i| {
            bullets[i].update();
            switch (bullets[i].hb_visibility) {
                Visibility.Visible => {
                    graphics.render_hitbox(window.renderer, bullets[i].hb);
                },
                Visibility.Invisible => {},
            }
            if (is_offscreen(bullets[i].x, bullets[i].y)) {
                bullets[i].reset();
            }
        }

        c.SDL_RenderPresent(window.renderer);
        c.SDL_Delay(1000 / FPS);
    }
}
