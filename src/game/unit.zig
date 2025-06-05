const shared = @import("shared.zig");

const GameState = @import("state.zig").GameState;
const UnitData = @import("unit_type.zig").UnitData;
const UnitType = @import("unit_type.zig").UnitType;
const StructureType = @import("structure.zig").StructureType;
const Structure = @import("structure.zig").Structure;

const EntityId = shared.EntityId;
const Position = shared.Position;

const BuildStage = union(enum) {
    WalkingToSite: void, // path maybe?
    Constructing: EntityId,
};

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
            .Move => |target| {
                const delta = target.sub(self.pos);
                const dist = delta.magnitue();

                if (dist < self.speed) {
                    self.pos = target;
                    self.intent = .None;
                } else {
                    self.pos = self.pos.add(delta.normalize().scale(self.speed));
                }
            },
            .Attack => |target_id| {
                const target = state.get_unit(target_id) orelse return;
                _ = target;
            },
            .Build => |build| {
                switch (build.stage) {
                    .WalkingToSite => {
                        const target = build.pos;
                        const delta = target.sub(self.pos);
                        const dist = delta.magnitue();
                        if (dist < self.speed) {
                            self.pos = target;
                            const entity_id = state.add_structure(Structure.create(self.owner_id, build.pos, build.kind));
                            self.intent.Build.stage = .{ .Constructing = entity_id };
                        } else {
                            self.pos = self.pos.add(delta.normalize().scale(self.speed));
                        }
                    },
                    .Constructing => |entity_id| {
                        if (!state.get_structure(entity_id).?.under_construction) {
                            self.intent = .None;
                        }
                    },
                }
            },
        }
    }

    pub const Intent = union(enum) {
        None,
        Move: Position,
        Attack: u32, // target unit id
        Build: struct {
            pos: Position,
            kind: StructureType,
            stage: BuildStage = .WalkingToSite,
        },
    };

    pub fn create(owner_id: u8, pos: Position, unit_type: UnitType) Self {
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
