const GameState = @import("../game.zig").GameState;

pub const Renderer = struct {
    draw: *const fn (state: GameState) void,
};
