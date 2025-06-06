const std = @import("std");
const testing = std.testing;

const game = @import("game");
const shared = game.shared;

const Simulation = game.Simulation;
const UnitType = game.UnitType;
const Intent = game.Unit.Intent;
const Position = shared.Position;
const GameState = game.GameState;

const test_soldier_speed = 1;
const allocator = std.testing.allocator;

test "two units move over multiple frames" {
    var gamestate: GameState = .init();
    var sim = Simulation.init(allocator, &gamestate);
    defer sim.deinit();

    // add two test units for two players
    const unit_a_id = sim.state.add_unit(game.Unit.create(0, .{ .x = 0, .y = 0 }, .TestSoldier));
    const unit_b_id = sim.state.add_unit(game.Unit.create(1, .{ .x = 10, .y = 0 }, .TestSoldier));

    sim.step(&[_]game.Command{
        .{ .MoveTo = .{ .pos = .{ .x = 1, .y = 0 }, .unit_id = unit_a_id } },
        .{ .MoveTo = .{ .pos = .{ .x = 0, .y = 0 }, .unit_id = unit_b_id } },
    });

    sim.step(&[_]game.Command{} ** 2);

    const unit_a = sim.state.get_unit(unit_a_id).?;
    const unit_b = sim.state.get_unit(unit_b_id).?;
    try testing.expectEqual(2, sim.command_log.items.len);
    try testing.expectEqual(2, sim.frame_index);

    try testing.expectEqual(1, unit_a.pos.x);
    // moving at a rate of 1 unit per frame, for 2 frames in a straight line
    try testing.expectApproxEqAbs(10 - test_soldier_speed * 2, unit_b.pos.x, 0.001);
}

test "units move diagonaly" {
    var gamestate: GameState = .init();
    var sim = Simulation.init(allocator, &gamestate);
    defer sim.deinit();

    const unit_id = sim.state.add_unit(game.Unit.create(0, .{ .x = 0, .y = 0 }, .TestSoldier));

    sim.step(&[_]game.Command{
        .{ .MoveTo = .{ .pos = .{ .x = 2, .y = 2 }, .unit_id = unit_id } },
    });

    sim.step(&[_]game.Command{} ** 2);

    const unit = sim.state.get_unit(unit_id).?;
    try testing.expectEqual(2, sim.command_log.items.len);
    try testing.expectEqual(2, sim.frame_index);

    // diagonal movement is 'shorter'
    try testing.expect(unit.pos.x < 2);
    try testing.expect(unit.pos.y < 2);
}

test "subsequent move commands" {
    var gamestate: GameState = .init();
    var sim = Simulation.init(allocator, &gamestate);
    defer sim.deinit();

    const unit_id = sim.state.add_unit(game.Unit.create(0, .{ .x = 0, .y = 0 }, .TestSoldier));

    sim.step(&[_]game.Command{
        .{ .MoveTo = .{ .pos = .{ .x = 20, .y = 0 }, .unit_id = unit_id } },
    });

    for (0..9) |_| sim.step(&[_]game.Command{});

    var unit = sim.state.get_unit(unit_id).?;
    try testing.expectEqual(10, unit.pos.x);
    try testing.expectEqual(0, unit.pos.y);

    sim.step(&[_]game.Command{
        .{ .MoveTo = .{ .pos = .{ .x = 10, .y = 20 }, .unit_id = unit_id } },
    });

    for (0..9) |_| sim.step(&[_]game.Command{});

    unit = sim.state.get_unit(unit_id).?;
    try testing.expectEqual(10, unit.pos.x);
    try testing.expectEqual(10, unit.pos.y);

    try testing.expectEqual(20, sim.command_log.items.len);
    try testing.expectEqual(20, sim.frame_index);
}

test "builder build" {
    var gamestate: GameState = .init();
    var sim = Simulation.init(allocator, &gamestate);
    defer sim.deinit();

    const unit_id = sim.state.add_unit(game.Unit.create(0, .{ .x = 0, .y = 0 }, .TestWorker));

    sim.step(&[_]game.Command{
        .{ .Build = .{ .pos = .{ .x = 20, .y = 0 }, .builder_id = unit_id, .structure_type = .thing } },
    });

    var unit = sim.state.get_unit(unit_id).?;
    try testing.expectEqual(.WalkingToSite, unit.get_intent().Build.stage);
    for (0..19) |_| sim.step(&[_]game.Command{});
    unit = sim.state.get_unit(unit_id).?;

    const structure_id = unit.get_intent().Build.stage.Constructing;
    var structure = sim.state.get_structure(structure_id).?;
    try testing.expect(structure.build_state != .Active);

    for (0..100) |_| sim.step(&[_]game.Command{});

    structure = sim.state.get_structure(structure_id).?;
    try testing.expect(structure.build_state == .Active);

    unit = sim.state.get_unit(unit_id).?;
    try testing.expectEqual(.None, unit.get_intent());
    try testing.expectEqual(20, unit.pos.x);
    try testing.expectEqual(0, unit.pos.y);
}

test "unit intent queue append" {
    var gamestate: GameState = .init();
    var sim = Simulation.init(allocator, &gamestate);
    defer sim.deinit();

    const unit_id = sim.state.add_unit(game.Unit.create(0, .{ .x = 0, .y = 0 }, .TestWorker));
    sim.step(&[_]game.Command{
        .{ .MoveTo = .{ .pos = .{ .x = 20, .y = 0 }, .unit_id = unit_id, .mode = .Append } },
    });

    sim.step(&[_]game.Command{
        .{ .MoveTo = .{ .pos = .{ .x = 20, .y = 20 }, .unit_id = unit_id, .mode = .Append } },
    });

    var unit = sim.state.get_unit(unit_id).?;
    try testing.expectEqual(2, unit.intent_count);
    for (0..50) |_| sim.step(&[_]game.Command{});
    unit = sim.state.get_unit(unit_id).?;

    try testing.expectEqual(20, unit.pos.x);
    try testing.expectEqual(20, unit.pos.y);
}

test "unit intent queue replace" {
    var gamestate: GameState = .init();
    var sim = Simulation.init(allocator, &gamestate);
    defer sim.deinit();

    const unit_id = sim.state.add_unit(game.Unit.create(0, .{ .x = 0, .y = 0 }, .TestWorker));
    sim.step(&[_]game.Command{
        .{ .MoveTo = .{ .pos = .{ .x = 20, .y = 0 }, .unit_id = unit_id, .mode = .Append } },
    });

    sim.step(&[_]game.Command{
        .{ .MoveTo = .{ .pos = .{ .x = 0, .y = 10 }, .unit_id = unit_id, .mode = .Replace } },
    });

    var unit = sim.state.get_unit(unit_id).?;
    // only one intent in queue
    try testing.expectEqual(1, unit.intent_count);

    // only stepping 9 frames, this would imply we would not have the time to make it
    // from 0,0 to 20,0 first, and then to 0,10
    // so we can assert that it's path is aborted in favour of traveling to 0,10 directly
    for (0..9) |_| sim.step(&[_]game.Command{});
    unit = sim.state.get_unit(unit_id).?;

    try testing.expectEqual(0, unit.pos.x);
    try testing.expectEqual(10, unit.pos.y);
}
