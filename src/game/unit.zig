const shared = @import("shared.zig");

const GameState = @import("state.zig");
const UnitData = @import("unit_type.zig").UnitData;
const UnitType = @import("unit_type.zig").UnitType;

const EntityId = shared.EntityId;
const Position = shared.Position;

pub const Unit = struct {
    // invalidated before given to ECS
    id: EntityId = 0,
    owner_id: u8,
    pos: Position,
    health: i32,
    max_health: i32,
    speed: f32,
    intent: Intent = .None,
    kind: UnitType,

    const Self = @This();
    pub fn update(self: *Self, state: *GameState) void {
        switch (self.intent) {
            .None => {},
            .Move => |dir| {
                self.pos.x += dir.dx * self.speed;
                self.pos.y += dir.dy * self.speed;
            },
            .Attack => |target_id| {
                const target = state.get_unit(target_id) orelse return;
                _ = target;
            },
        }
        self.intent = .None;
    }

    pub const Intent = union(enum) {
        None,
        Move: Position,
        Attack: u32, // target unit id
    };

    pub fn create_unit(owner_id: u8, pos: Position, unit_type: UnitType) Self {
        const data = UnitData.get(unit_type);
        return .{
            .health = data.health,
            .speed = data.speed,
            .pos = pos,
            .owner_id = owner_id,
            .max_health = data.health,
            .kind = unit_type,
        };
    }
};
