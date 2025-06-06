const shared = @import("shared.zig");
const GameState = @import("state.zig").GameState;
const EntityId = shared.EntityId;
const Position = shared.Position;

pub const StructureType = enum {
    thing,

    pub fn get_construction_cost_frames(t: StructureType) u32 {
        return switch (t) {
            .thing => 60,
        };
    }
};

pub const BuildState = union(enum) {
    Constructing: u32,
    Active,
};

pub const Structure = struct {
    id: EntityId = 0,
    owner_id: u8,

    pos: Position,
    kind: StructureType,

    health: i32,
    max_health: i32,

    build_state: BuildState,

    rally_pos: ?Position = null,

    const Self = @This();
    pub fn update(self: *Self, gamestate: *GameState) void {
        _ = gamestate;
        switch (self.build_state) {
            .Constructing => |remaining| {
                if (remaining <= 1) {
                    self.build_state = .Active;
                } else {
                    self.build_state = .{ .Constructing = remaining - 1 };
                }
            },
            .Active => {},
        }
    }

    pub fn create(owner_id: u8, pos: Position, kind: StructureType) Self {
        return .{
            .owner_id = owner_id,
            .pos = pos,
            .kind = kind,

            .health = 0,
            .max_health = 100,
            .build_state = .{ .Constructing = kind.get_construction_cost_frames() },
        };
    }
};
