const std = @import("std");
const Command = @import("commands.zig").Command;
const GameState = @import("state.zig").GameState;

pub const Simulation = struct {
    state: *GameState,
    frame_index: u32 = 0,
    command_log: std.ArrayListUnmanaged([]const Command),
    allocator: std.mem.Allocator,

    const Self = @This();
    pub fn init(allocator: std.mem.Allocator, state: *GameState) Self {
        return .{
            .allocator = allocator,
            .state = state,
            .command_log = .{},
        };
    }

    pub fn step(self: *Self, frame_cmds: []const Command) void {
        std.log.info("{any}", .{frame_cmds});
        self.command_log.append(self.allocator, frame_cmds) catch unreachable;

        for (frame_cmds) |cmd| {
            cmd.apply(self.state);
        }

        self.update();

        self.frame_index += 1;
    }

    fn update(self: Self) void {
        _ = self;
    }

    pub fn reset(self: *Simulation) void {
        self.frame_index = 0;
        self.command_log.clearRetainingCapacity();
    }

    pub fn deinit(self: *Simulation) void {
        self.command_log.deinit(self.allocator);
    }
};
