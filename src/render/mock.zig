const GameState = @import("../game.zig").GameState;
const Renderer = @import("interface.zig").Renderer;

const Self = @This();
fn draw(state: GameState) void {
    _ = state;
}

pub fn renderer() Renderer {
    return .{
        .draw = draw,
    };
}
