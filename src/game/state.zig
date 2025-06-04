const std = @import("std");

const shared = @import("shared.zig");
const Unit = @import("unit.zig").Unit;

const EntityId = shared.EntityId;
const Frame = shared.Frame;
const Position = shared.Position;

pub const MaxUnits = 1024;
pub const MaxStructures = 255;
pub const MaxPlayers = 8;

const Structure = struct {
    const Self = @This();

    pub fn update(self: *Self) void {
        _ = self;
    }
};

const Player = struct {};

pub const GameState = struct {
    frame: u32,
    units: [MaxUnits]Unit,
    unit_count: usize,
    structures: [MaxStructures]Structure,
    structure_count: usize,
    players: [MaxPlayers]Player,
    player_count: usize,
    next_unit_id: EntityId = 1,

    const Self = @This();
    pub fn init() GameState {
        return GameState{
            .frame = 0,
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

    pub fn get_unit(self: *GameState, id: EntityId) ?*const Unit {
        for (self.units[0..self.unit_count]) |*u| {
            if (u.id == id) return u;
        }
        return null;
    }

    pub fn get_unit_mut(self: *GameState, id: EntityId) ?*Unit {
        for (self.units[0..self.unit_count]) |*u| {
            if (u.id == id) return u;
        }
        return null;
    }

    pub fn step(self: *GameState) void {
        for (self.units[0..self.unit_count]) |*unit| {
            unit.update(self);
        }
        for (self.structures[0..self.structure_count]) |*s| {
            s.update(self);
        }
        self.frame += 1;
    }
};
