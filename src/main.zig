const std = @import("std");
const Engine = @import("engine.zig").Engine;
const render = @import("render.zig");
const game = @import("game.zig");
const net = @import("net.zig");

pub fn main() void {
    var DBA = std.heap.DebugAllocator(.{}){};
    const allocator = DBA.allocator();

    var state: game.GameState = .init();
    var engine: Engine = .{ .draw = render.Mock.renderer(), .net = .init(allocator, 2), .sim = .init(allocator, &state) };

    engine.tick();
}
