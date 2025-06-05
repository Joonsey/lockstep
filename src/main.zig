const std = @import("std");
const Engine = @import("engine.zig").Engine;
const render = @import("render.zig");
const game = @import("game.zig");
const net = @import("net.zig");

pub fn main() void {
    var DBA = std.heap.DebugAllocator(.{}){};
    defer switch (DBA.deinit()) {
        .leak => {
            std.log.err("memory leaks detected!", .{});
        },
        .ok => {},
    };

    const allocator = DBA.allocator();

    var state: game.GameState = .init();
    var engine: Engine = .{ .draw = render.Mock.renderer(), .net = .init(allocator, 2), .sim = .init(allocator, &state) };
    defer engine.deinit();

    engine.net.submit_command(0, 0, .None);
    engine.net.submit_command(1, 0, .None);
    engine.tick();
}

test {
    @import("std").testing.refAllDecls(@This());
}
