const std = @import("std");
const graphics = @import("graphics.zig");
const entities = @import("entities.zig");
const Window = graphics.Window;
const Color = graphics.Color;
const Player = entities.Player;
const Bullet = entities.Bullet;
const Hitbox = entities.Hitbox;
const Visibility = entities.Visibility;
const StandardEnemy = entities.StandardEnemy;
const handle_player_event = @import("input.zig").handle_player_event;
const overlaps = c.SDL_HasIntersection;
const allocator = std.heap.page_allocator;

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

fn collides(e1: Hitbox, e2: Hitbox) bool {
    const e1_rect = graphics.make_sdl_rect(e1.x, e1.y, e1.w, e1.h);
    const e2_rect = graphics.make_sdl_rect(e2.x, e2.y, e2.w, e2.h);
    if (overlaps(&e1_rect, &e2_rect) != 0) {
        return true;
    }
    return false;
}

var quit = false;
var pause = false;
var enemies_killed: u32 = 0;
pub fn main() !void {
    var window: Window = try Window.init("ShooterGame", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);
    defer window.deinit();

    var player: Player = Player.init(300, 300, 20);
    var bullets = create_bullets();
    var temp_enemy: StandardEnemy = StandardEnemy.init(WINDOW_WIDTH / 3, WINDOW_HEIGHT / 3);
    var enemies_killed_msg: graphics.ScreenText = try graphics.ScreenText.init(40, 40, 24, Color.white, "Enemies Killed: 0", window.renderer);
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

        temp_enemy.update();
        if (is_offscreen(temp_enemy.x, temp_enemy.y)) {
            temp_enemy.dx *= -1;
            temp_enemy.dy *= -1;
        }
        switch (temp_enemy.hb_visibility) {
            Visibility.Visible => {
                graphics.render_hitbox(window.renderer, temp_enemy.hb);
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
            switch (temp_enemy.hb_visibility) {
                Visibility.Visible => {
                    if (collides(bullets[i].hb, temp_enemy.hb)) {
                        temp_enemy.hit(1);
                        if (temp_enemy.destroy()) {
                            enemies_killed += 1;
                        }
                        bullets[i].reset();
                    }
                },
                Visibility.Invisible => {},
            }
        }

        var tmp_string = try std.fmt.allocPrint(allocator, "enemies killed: {d}", .{enemies_killed});
        defer allocator.free(tmp_string);

        try enemies_killed_msg.render(window.renderer, tmp_string);

        c.SDL_RenderPresent(window.renderer);
        c.SDL_Delay(1000 / FPS);
    }
}
