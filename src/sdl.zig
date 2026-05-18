const std = @import("std");

pub const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

pub fn sdlPanic() noreturn {
    const str = @as(?[*:0]const u8, c.SDL_GetError()) orelse "unknown error";
    @panic(std.mem.sliceTo(str, 0));
}

pub fn initSDL() struct { *c.SDL_Window, *c.SDL_Renderer } {
    if (c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_EVENTS | c.SDL_INIT_AUDIO) < 0)
        sdlPanic();

    const window = c.SDL_CreateWindow(
        "nes",
        c.SDL_WINDOWPOS_CENTERED,
        c.SDL_WINDOWPOS_CENTERED,
        32 * 10, // 720
        32 * 10, // 360
        c.SDL_WINDOW_SHOWN,
    ) orelse sdlPanic();

    const renderer = c.SDL_CreateRenderer(window, -1, c.SDL_RENDERER_ACCELERATED) orelse sdlPanic();

    _ = c.SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xFF);
    c.SDL_RenderPresent(renderer);
    _ = c.SDL_RenderClear(renderer);

    return .{ window, renderer };
}

pub fn closeSDL(window: *c.SDL_Window, renderer: *c.SDL_Renderer) void {
    defer c.SDL_Quit();
    defer _ = c.SDL_DestroyRenderer(renderer);
    defer _ = c.SDL_DestroyWindow(window);
}
