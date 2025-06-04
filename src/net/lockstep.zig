const std = @import("std");

const Command = @import("../game/commands.zig").Command;
const game_state = @import("../game/state.zig");
const MaxPlayers = game_state.MaxPlayers;

const CommandBuffer = std.AutoHashMapUnmanaged(u32, [MaxPlayers]?Command);
pub const Lockstep = struct {
    frame: u32,
    player_count: usize,
    command_buffer: CommandBuffer,

    allocator: std.mem.Allocator,

    const Self = @This();
    pub fn init(allocator: std.mem.Allocator, player_count: usize) Self {
        return .{
            .allocator = allocator,
            .player_count = player_count,
            .frame = 0,
            .command_buffer = .{},
        };
    }

    pub fn get_next_frame_commands(self: *Lockstep) ?[MaxPlayers]Command {
        if (!self.frame_ready(self.frame)) return null;
        const slot = self.command_buffer.get(self.frame).?;
        var commands: [MaxPlayers]Command = undefined;
        var i: usize = 0;
        while (i < self.player_count) : (i += 1) {
            commands[i] = slot[i].?;
        }
        _ = self.command_buffer.remove(self.frame);
        self.frame += 1;
        return commands;
    }

    pub fn submit_command(self: *Lockstep, player_id: u8, frame: u32, command: Command) void {
        const entry = self.command_buffer.getOrPut(self.allocator, frame) catch return;
        if (!entry.found_existing) {
            entry.value_ptr.* = [_]?Command{.NONE} ** MaxPlayers;
        }
        entry.value_ptr.*[player_id] = command;
    }

    pub fn frame_ready(self: *Lockstep, frame: u32) bool {
        const slot = self.command_buffer.get(frame) orelse return false;
        var i: usize = 0;
        while (i < self.player_count) : (i += 1) {
            if (slot[i] == null) return false;
        }
        return true;
    }

    pub fn peek_frame(self: *Lockstep, frame: u32) ?[MaxPlayers]?Command {
        return self.command_buffer.get(frame);
    }

    pub fn reset(self: *Lockstep) void {
        self.frame = 0;
        self.command_buffer.clearRetainingCapacity();
    }

    pub fn deinit(self: *Self) void {
        self.command_buffer.clearAndFree(self.allocator);
    }
};
