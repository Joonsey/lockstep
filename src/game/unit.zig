const shared = @import("shared.zig");

const GameState = @import("state.zig").GameState;
const UnitData = @import("unit_type.zig").UnitData;
const UnitType = @import("unit_type.zig").UnitType;
const StructureType = @import("structure.zig").StructureType;
const Structure = @import("structure.zig").Structure;

const EntityId = shared.EntityId;
const Position = shared.Position;
const MaxIntentQueue = 128;

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
    kind: UnitType,

    intent_queue: [MaxIntentQueue]Intent,
    intent_count: usize = 0,

    const Self = @This();
    pub fn update(self: *Self, state: *GameState) void {
        switch (self.get_intent()) {
            .None => {},
            .Move => |target| {
                const delta = target.sub(self.pos);
                const dist = delta.magnitue();

                if (dist < self.speed) {
                    self.pos = target;
                    self.complete_intent();
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
                            var intent = self.get_intent();
                            intent.Build.stage = .{ .Constructing = entity_id };
                            self.push_intent(intent);
                            self.complete_intent();
                        } else {
                            self.pos = self.pos.add(delta.normalize().scale(self.speed));
                        }
                    },
                    .Constructing => |entity_id| {
                        if (state.get_structure(entity_id).?.build_state == .Active) {
                            self.complete_intent();
                        }
                    },
                }
            },
        }
    }

    pub fn get_intent(self: Self) Intent {
        return self.intent_queue[0];
    }

    pub fn push_intent(self: *Self, intent: Intent) void {
        self.intent_queue[self.intent_count] = intent;

        // techinically prone to overflow, this value can not really be higher than 128 or it will break
        // don't care to treat this, extremely unreasonable scenario IMO
        self.intent_count += 1;
    }

    pub fn reset_intent(self: *Self) void {
        self.intent_count = 0;
        self.intent_queue[0] = .None;
    }

    pub fn complete_intent(self: *Self) void {
        if (self.intent_count < 1) {
            // if we are last intent in queue, we simply set to .None
            self.intent_queue[0] = .None;
            return;
        }

        for (0..self.intent_count - 1) |i| {
            self.intent_queue[i] = self.intent_queue[i + 1];
        }
        self.intent_count -= 1;
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
            .intent_queue = [_]Intent{.None} ** MaxIntentQueue,
        };
    }
};

const testing = @import("std").testing;
test "initialized unit intent queue" {
    const unit = Unit.create(0, .zero(), .TestSoldier);
    try testing.expectEqual(.None, unit.get_intent());
}

test "unit intent queue multiple items in queue" {
    var unit = Unit.create(0, .zero(), .TestSoldier);

    // push move command to intent queue
    unit.push_intent(.{ .Move = .zero() });
    // asserting it is the 'current intent'
    try testing.expectEqual(Unit.Intent{ .Move = .zero() }, unit.get_intent());

    // push attack command to intent queue
    unit.push_intent(.{ .Attack = 29 });
    // asserting the length of the queue is 2
    try testing.expectEqual(unit.intent_count, 2);

    // 'completing' move intent
    unit.complete_intent();
    // new 'current intent' should be the attack intent
    try testing.expectEqual(Unit.Intent{ .Attack = 29 }, unit.get_intent());

    // queue length should now be 1, as only the attack intent is remaining in the queue
    try testing.expectEqual(unit.intent_count, 1);
}

test "reset unit intent should become 'None'" {
    var unit = Unit.create(0, .zero(), .TestSoldier);
    unit.push_intent(.{ .Move = .zero() });
    try testing.expectEqual(Unit.Intent{ .Move = .zero() }, unit.get_intent());

    unit.reset_intent();

    try testing.expectEqual(.None, unit.get_intent());
    try testing.expectEqual(unit.intent_count, 0);
}

test "complete intent on empty intent array" {
    var unit = Unit.create(0, .zero(), .TestSoldier);
    unit.complete_intent();
}
