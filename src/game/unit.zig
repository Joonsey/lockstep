const shared = @import("shared.zig");

const GameState = @import("state.zig");

const EntityId = shared.EntityId;
const Position = shared.Position;

pub const Unit = struct {
    id: EntityId,
    owner_id: u8,
    pos: Position,
    health: i32,
    max_health: i32,
    speed: f32, // Movement speed units per frame
    intent: Intent,

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
        Move: struct { dx: f32, dy: f32 },
        Attack: u32, // target unit id
    };
};
