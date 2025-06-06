const std = @import("std");

const game = @import("game.zig");
const net = @import("net.zig");
const render = @import("render.zig");
const map = @import("map.zig");

pub const Engine = struct {
    sim: game.Simulation,
    net: net.Lockstep,
    draw: render.Renderer,

    pub fn tick(self: *Engine) void {
        if (self.net.get_next_frame_commands()) |commands| {
            self.sim.step(commands[0..self.net.player_count]);
            self.draw.draw(self.sim.state.*); // no-op if headless
        }
    }

    pub fn deinit(self: *Engine) void {
        self.sim.deinit();
        self.net.deinit();
    }
};
