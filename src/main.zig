const std = @import("std");
const graphics = @import("graphics.zig");
const entities = @import("entities.zig");
const gui = @import("gui.zig");
const audio = @import("audio.zig");

const c = @import("c.zig");

const SoundEffect = audio.SoundEffect;
const Music = audio.Music;

const Color = graphics.Color;
const Sprite = graphics.Sprite;
const TextureMap = graphics.TextureMap;
const TileID = graphics.TileID;
const Tilemap = graphics.Tilemap;
const Viewport = graphics.Viewport;
const Window = graphics.Window;

const Bullet = entities.Bullet;
const Player = entities.Player;
const Visibility = entities.Visibility;
const Hitbox = entities.Hitbox;
const StandardEnemy = entities.StandardEnemy;

const handle_player_event = @import("input.zig").handle_player_event;
const overlaps = c.SDL_HasIntersection;
const allocator = std.heap.page_allocator;

const FPS = 60;
const BACKGROUND_COLOR = Color.dark_gray;
const WORLD_WIDTH = 2800;
const WORLD_HEIGHT = 2800;
const TILE_WIDTH = 10;
const TILE_HEIGHT = 10;
const BULLET_COUNT = 10;
const PLAYER_SPRITE_PATH = "assets/images/basic_player.png";

fn set_render_color(renderer: *c.SDL_Renderer, col: c.SDL_Color) void {
    _ = c.SDL_SetRenderDrawColor(renderer, col.r, col.g, col.b, col.a);
}

fn as_rect(hb: Hitbox) c.SDL_Rect {
    return c.SDL_Rect{
        .x = @as(c_int, @intFromFloat(hb.x)),
        .y = @as(c_int, @intFromFloat(hb.y)),
        .w = @as(c_int, @intFromFloat(hb.w)),
        .h = @as(c_int, @intFromFloat(hb.h)),
    };
}

fn create_bullets(gs: SoundEffect) [BULLET_COUNT]Bullet {
    var bullets: [BULLET_COUNT]Bullet = undefined;
    for (0..BULLET_COUNT) |index| {
        bullets[index] = Bullet.init(BULLET_COUNT, gs);
    }
    return bullets;
}

fn is_offscreen(x: f32, y: f32) bool {
    if (x < 0 or x > @as(f32, @floatFromInt(window_width))) {
        return true;
    } else if (y < 0 or y > @as(f32, @floatFromInt(window_height))) {
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

var window_width: u32 = 800;
var window_height: u32 = 600;
var quit = false;
var pause = false;
var enemies_killed: u32 = 0;
pub fn main() !void {
    var window: Window = try Window.init("ShooterGame", 0, 0, window_width, window_height);
    defer window.deinit();

    audio.open_audio(44100, 8, 2048);
    defer audio.close_audio();

    var viewport: Viewport = Viewport.init(0, 0, @intCast(window_width), @intCast(window_height));

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();

    var arena = std.heap.ArenaAllocator.init(alloc);
    var arena_alloc = arena.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    const map_file = if (args.len > 1) args[1] else "assets/maps/next_test";

    var tex_map = try TextureMap.init(alloc, arena_alloc, window.renderer, @constCast(@ptrCast("assets/textures/")));
    defer tex_map.deinit();
    var tilemap: Tilemap = try Tilemap.init(map_file, alloc, &tex_map, TILE_WIDTH, TILE_HEIGHT, WORLD_WIDTH, WORLD_HEIGHT);

    var music: Music = Music.init("assets/sounds/music/8_Bit_Nostalgia.mp3");
    defer music.deinit();

    // BEGIN sound effects
    var grass_step: SoundEffect = SoundEffect.init("assets/sounds/effects/grass_step.wav", true);
    defer grass_step.deinit();

    var gunshot: SoundEffect = SoundEffect.init("assets/sounds/effects/gunshot.wav", false);
    defer gunshot.deinit();

    // END sound effects

    var player_sprite = Sprite.init(window.renderer, PLAYER_SPRITE_PATH);
    defer player_sprite.deinit();
    var player: Player = Player.init(player_sprite, 300, 300, 20, grass_step);

    var bullets = create_bullets(gunshot);

    var temp_enemy: StandardEnemy = StandardEnemy.init(window_width / 3, window_height / 3);
    var enemies_killed_msg: graphics.ScreenText = try graphics.ScreenText.init(40, 40, 24, Color.white, "Enemies Killed: 0", window.renderer);

    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            handle_player_event(&window, viewport, event, &player, &bullets);
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
                        if (music.playing) {
                            music.toggle_pause();
                        } else {
                            music.play();
                        }
                    },
                    else => {},
                },
                else => {},
            }
        }

        window.update();
        window_width = window.width;
        window_height = window.height;
        set_render_color(window.renderer, Color.make_sdl_color(BACKGROUND_COLOR));
        _ = c.SDL_RenderClear(window.renderer);

        // *** TODO: BREAK AND RE-IMPLEMENT ***
        viewport.update();
        tilemap.render(window.renderer, &viewport, window);

        player.update();
        player.sprite.render(window.renderer, as_rect(player.hb), &viewport);
        switch (player.hb_visibility) {
            Visibility.Visible => {
                graphics.render_hitbox(window.renderer, player.hb, &viewport);
            },
            Visibility.Invisible => {},
        }

        temp_enemy.update();
        if (temp_enemy.x > WORLD_WIDTH or temp_enemy.y > WORLD_HEIGHT) {
            temp_enemy.destroy();
        }
        switch (temp_enemy.hb_visibility) {
            Visibility.Visible => {
                graphics.render_hitbox(window.renderer, temp_enemy.hb, &viewport);
            },
            Visibility.Invisible => {},
        }

        for (0..bullets.len) |i| {
            bullets[i].update();
            switch (bullets[i].hb_visibility) {
                Visibility.Visible => {
                    graphics.render_hitbox(window.renderer, bullets[i].hb, &viewport);
                },
                Visibility.Invisible => {},
            }
            if (!viewport.can_see(@intFromFloat(bullets[i].x), @intFromFloat(bullets[i].y), @intFromFloat(bullets[i].hb.w), @intFromFloat(bullets[i].hb.h))) {
                bullets[i].reset();
            }
            switch (temp_enemy.hb_visibility) {
                Visibility.Visible => {
                    if (collides(bullets[i].hb, temp_enemy.hb)) {
                        temp_enemy.hit(1);
                        if (temp_enemy.destroyed()) {
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
