const std = @import("std");

const shared = @import("../game.zig").shared;
const Path = @import("../game/path.zig").Path;

const Vec2 = @import("../util/math.zig").Vec2;

const EntityId = shared.EntityId;

pub const Tile = struct {
    walkable: bool,
    occupied: ?EntityId = null,

    // resource node?
    // visibility stats?
};

pub const LogicalMap = struct {
    width: usize,
    height: usize,
    tiles: []Tile = undefined,

    walkability_cache: [][]bool = undefined,

    const Self = @This();

    pub fn at(self: Self, x: usize, y: usize) Tile {
        return self.tiles[y * self.width + x];
    }

    fn at_mut(self: *Self, x: usize, y: usize) *Tile {
        return &self.tiles[y * self.width + x];
    }

    pub fn build_cache(self: *Self, allocator: std.mem.Allocator) void {
        var x: std.ArrayListUnmanaged(bool) = .{};
        var y: std.ArrayListUnmanaged([]bool) = .{};
        for (0..self.height) |i| {
            for (0..self.width) |j| {
                const tile = self.at(j, i);
                x.append(allocator, tile.occupied == null and !tile.walkable) catch unreachable;
            }

            y.append(allocator, x.toOwnedSlice(allocator) catch unreachable) catch unreachable;
        }

        self.walkability_cache = y.toOwnedSlice(allocator) catch unreachable;
    }

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        for (self.walkability_cache) |item| {
            allocator.free(item);
        }
        allocator.free(self.walkability_cache);
        allocator.free(self.tiles);
    }

    pub fn set_occupied(self: *Self, x: usize, y: usize, value: ?EntityId) void {
        const idx = y * self.width + x;
        self.tiles[idx].occupied = value;
        self.walkability_cache[idx] = self.tiles[idx].walkable and (value == null);
    }

    pub fn find_path(self: Self, allocator: std.mem.Allocator, start: Vec2, goal: Vec2) !Path {
        return Path.find(allocator, self.walkability_cache, start, goal);
    }
};

test "simple logical map pathfinding" {
    const allocator = std.testing.allocator;
    var map: LogicalMap = .{ .height = 6, .width = 6 };

    var tiles: std.ArrayListUnmanaged(Tile) = .{};
    try tiles.appendNTimes(allocator, .{ .occupied = null, .walkable = true }, 6);
    try tiles.appendNTimes(allocator, .{ .occupied = null, .walkable = true }, 6);
    try tiles.appendNTimes(allocator, .{ .occupied = null, .walkable = true }, 6);
    try tiles.appendNTimes(allocator, .{ .occupied = null, .walkable = true }, 2);
    try tiles.appendNTimes(allocator, .{ .occupied = null, .walkable = false }, 2);
    try tiles.appendNTimes(allocator, .{ .occupied = null, .walkable = true }, 2);
    try tiles.appendNTimes(allocator, .{ .occupied = null, .walkable = true }, 6);
    try tiles.appendNTimes(allocator, .{ .occupied = null, .walkable = true }, 6);
    map.tiles = try tiles.toOwnedSlice(allocator);

    map.build_cache(allocator);
    defer map.deinit(allocator);

    const path = try map.find_path(allocator, .{ .x = 0, .y = 0 }, .{ .x = 5, .y = 5 });
    defer path.deinit(allocator);
}

test "large logical map pathfinding" {
    const allocator = std.testing.allocator;
    var map: LogicalMap = .{ .height = 600, .width = 600 };

    var tiles: std.ArrayListUnmanaged(Tile) = .{};
    try tiles.appendNTimes(allocator, .{ .occupied = null, .walkable = true }, 600 * 600);
    map.tiles = try tiles.toOwnedSlice(allocator);
    map.build_cache(allocator);
    defer map.deinit(allocator);

    // this takes up to 20ms
    // which is greater than the duration of a frame, which means we would fall behind each time we run a pathfinding algorithm
    // consider chunking it up between parts of the map?
    // consider limiting map size?
    // consider letting units share path?
    const path = try map.find_path(allocator, .{ .x = 0, .y = 0 }, .{ .x = 102, .y = 255 });
    defer path.deinit(allocator);
}

test "(I think) normal sized logical map pathfinding" {
    const allocator = std.testing.allocator;
    const width = 128;
    const height = 128;
    var map: LogicalMap = .{ .height = height, .width = width };

    var tiles: std.ArrayListUnmanaged(Tile) = .{};
    try tiles.appendNTimes(allocator, .{ .occupied = null, .walkable = true }, height * width);
    map.tiles = try tiles.toOwnedSlice(allocator);
    map.build_cache(allocator);
    defer map.deinit(allocator);

    // takes about 3ms, that is okay
    const path = try map.find_path(allocator, .{ .x = 0, .y = 0 }, .{ .x = 102, .y = 88 });
    defer path.deinit(allocator);
}
