const shared = @import("shared.zig");
const GameState = @import("state.zig").GameState;
const EntityId = shared.EntityId;
const Position = shared.Position;

pub const StructureType = enum {
    thing,
};

pub const Structure = struct {
    id: EntityId = 0,
    owner_id: u8,

    pos: Position,
    kind: StructureType,

    health: i32,
    max_health: i32,

    under_construction: bool = true,
    build_progress: f32 = 0.0,

    is_active: bool = false,
    rally_pos: ?Position = null,

    const Self = @This();

    pub fn update(self: *Self, gamestate: *GameState) void {
        _ = gamestate;
        if (self.under_construction) {
            self.build_progress += 0.01; // or from builder rate
            if (self.build_progress >= 1.0) {
                self.under_construction = false;
                self.is_active = true;
                self.health = self.max_health;
            }
        }
    }

    pub fn create(owner_id: u8, pos: Position, kind: StructureType) Self {
        return .{
            .owner_id = owner_id,
            .pos = pos,
            .kind = kind,

            .health = 0,
            .max_health = 100,
        };
    }
};
