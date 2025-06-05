const std = @import("std");
const GameState = @import("state.zig").GameState;
const StructureType = @import("structure.zig").StructureType;
const shared = @import("shared.zig");

const EntityId = shared.EntityId;
const Frame = shared.Frame;
const Position = shared.Position;

pub const Command = union(enum) {
    None: void,
    MoveTo: struct {
        unit_id: EntityId,
        pos: Position,
        mode: Mode = .Replace,
    },
    Attack: struct {
        unit_id: EntityId,
        target_id: EntityId,
        mode: Mode = .Replace,
    },
    Build: struct {
        builder_id: EntityId,
        structure_type: StructureType,
        pos: Position,
        mode: Mode = .Replace,
    },
    SetRallyPoint: struct {
        building_id: EntityId,
        target_pos: Position,
        mode: Mode = .Replace,
    },
    CancelBuild: struct {
        queue_owner_id: EntityId,
    },

    // Queue mode
    pub const Mode = enum {
        Replace,
        Append,
    };

    pub fn apply(self: Command, state: *GameState) void {
        switch (self) {
            .None => {}, // no-op
            .MoveTo => |cmd| {
                const unit = state.get_unit_mut(cmd.unit_id) orelse return;
                if (cmd.mode == .Replace) unit.reset_intent();
                unit.push_intent(.{ .Move = cmd.pos });
            },
            .Attack => |cmd| {
                const unit = state.get_unit_mut(cmd.unit_id) orelse return;
                // if (cmd.mode == .Replace) unit.reset_intent();
                // unit.push_intent(.{ .Move = cmd.pos });
                _ = unit;
                // unit.intent = .{ .attack_target = cmd.target_id };
            },
            .Build => |cmd| {
                const builder = state.get_unit_mut(cmd.builder_id) orelse return;
                if (cmd.mode == .Replace) builder.reset_intent();
                builder.push_intent(.{ .Build = .{ .pos = cmd.pos, .kind = cmd.structure_type } });
            },
            .SetRallyPoint => |cmd| {
                const b = state.get_unit_mut(cmd.building_id) orelse return;
                _ = b;
                // b.rally_point = cmd.target_pos;
            },
            .CancelBuild => |_| {
                // const q = state.get_queue_mut(cmd.queue_owner_id) orelse return;
                // _ = q;
                // q.cancel();
            },
        }
    }
};
