const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_audio.h");
});

// TODO:
// - setup sdl audio test in separate dir
// - port sdl audio config over and provide bindings
