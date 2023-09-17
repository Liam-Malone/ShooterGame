const std = @import("std");
const audio = @import("../src/audio.zig");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_mixer.h");
});

test "audio asset loading" {
    // TODO:
    //  - write test to ensure that audio opens
    //  - ensure sound effects can be loaded
}
