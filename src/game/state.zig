const std = @import("std");

const shared = @import("shared.zig");
const Unit = @import("unit.zig").Unit;
const Structure = @import("structure.zig").Structure;

const EntityId = shared.EntityId;
const Frame = shared.Frame;
const Position = shared.Position;

pub const MaxUnits = 1024;
pub const MaxStructures = 255;
pub const MaxPlayers = 8;

const Player = struct {};

pub const GameState = struct {
    units: [MaxUnits]Unit,
    unit_count: usize,
    structures: [MaxStructures]Structure,
    structure_count: usize,
    players: [MaxPlayers]Player,
    player_count: usize,
    next_unit_id: EntityId = 1,
    next_structure_id: EntityId = 1,

    const Self = @This();
    pub fn init() GameState {
        return GameState{
            .units = undefined,
            .unit_count = 0,
            .structures = undefined,
            .structure_count = 0,
            .players = undefined,
            .player_count = 0,
        };
    }

    pub fn add_unit(self: *GameState, unit: Unit) EntityId {
        const id = self.next_unit_id;
        self.next_unit_id += 1;

        const idx = self.unit_count;
        self.units[idx] = unit;
        self.units[idx].id = id;
        self.unit_count += 1;

        return id;
    }

    pub fn get_units(self: *Self) []Unit {
        return self.units[0..self.unit_count];
    }

    pub fn get_unit(self: *Self, id: EntityId) ?*const Unit {
        for (self.units[0..self.unit_count]) |*u| {
            if (u.id == id) return u;
        }
        return null;
    }

    pub fn get_unit_mut(self: *Self, id: EntityId) ?*Unit {
        for (self.units[0..self.unit_count]) |*u| {
            if (u.id == id) return u;
        }
        return null;
    }

    pub fn get_structures(self: *Self) []Structure {
        return self.structures[0..self.structure_count];
    }

    pub fn get_structure(self: *Self, id: EntityId) ?*const Structure {
        for (self.structures[0..self.structure_count]) |*s| {
            if (s.id == id) return s;
        }
        return null;
    }

    pub fn get_structure_mut(self: *Self, id: EntityId) ?*Structure {
        for (self.structures[0..self.structure_count]) |*s| {
            if (s.id == id) return s;
        }
        return null;
    }

    pub fn add_structure(self: *Self, structure: Structure) EntityId {
        const id = self.next_structure_id;
        self.next_structure_id += 1;

        const idx = self.structure_count;
        self.structures[idx] = structure;
        self.structures[idx].id = id;
        self.structure_count += 1;

        return id;
    }
};

test "add unit" {
    var gs: GameState = .init();
    const entityId = gs.add_unit(Unit.create(0, .zero(), .TestWorker));

    try std.testing.expectEqual(2, gs.next_unit_id);

    const entity = gs.get_unit(entityId).?;
    try std.testing.expectEqual(1, entity.id);
}

test "add structure" {
    var gs: GameState = .init();
    const entityId = gs.add_structure(Structure.create(0, .zero(), .thing));

    try std.testing.expectEqual(2, gs.next_structure_id);

    const entity = gs.get_structure(entityId).?;
    try std.testing.expectEqual(1, entity.id);
}
