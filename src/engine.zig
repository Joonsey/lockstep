const game = @import("game.zig");
const net = @import("net.zig");
const render = @import("render.zig");

pub const Engine = struct {
    sim: game.Simulation,
    net: net.Lockstep,
    draw: render.Renderer, // interface, stubbed headless

    pub fn tick(self: *Engine) void {
        if (self.net.get_next_frame_commands()) |commands| {
            self.sim.step(commands[0..0]);
            self.draw.draw(self.sim.state.*); // no-op if headless
        }
    }
};
