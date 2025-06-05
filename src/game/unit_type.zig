pub const UnitType = enum {
    TestSoldier,
    TestWorker,

    Soldier,
    Worker,
};

pub const UnitData = struct {
    health: i32,
    speed: f32,

    pub fn get(t: UnitType) UnitData {
        return switch (t) {
            .TestSoldier => .{ .health = 10, .speed = 1.0 },
            .TestWorker => .{ .health = 5, .speed = 1.2 },
            .Soldier => .{ .health = 50, .speed = 2.5 },
            .Worker => .{ .health = 20, .speed = 1.5 },
        };
    }
};
