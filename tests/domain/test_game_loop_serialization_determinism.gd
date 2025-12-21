extends GutTest
## Determinism check for domain game loop

const GameLoop = preload("res://src/domain/game_loop.gd")
const GameState = preload("res://src/domain/aggregates/game_state.gd")
const StageState = preload("res://src/domain/aggregates/stage_state.gd")
const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const MoveCommand = preload("res://src/domain/commands/move_command.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")

## BDD: Given identical inputs When processing twice Then serialized events match
func test_given_identical_state_and_commands_when_processed_twice_then_serialized_events_match():
	var stage_a = StageState.create(1, 26, 26)
	stage_a.set_base(Position.create(12, 24))
	var state_a = GameState.create(stage_a, 3)
	state_a.spawn_controller = null # avoid random spawns
	
	var stage_b = StageState.create(1, 26, 26)
	stage_b.set_base(Position.create(12, 24))
	var state_b = GameState.create(stage_b, 3)
	state_b.spawn_controller = null # avoid random spawns
	
	var tank_a = TankEntity.create("p1", TankEntity.Type.PLAYER, Position.create(8, 8), Direction.create(Direction.RIGHT))
	var tank_b = TankEntity.create("p1", TankEntity.Type.PLAYER, Position.create(8, 8), Direction.create(Direction.RIGHT))
	state_a.add_tank(tank_a)
	state_b.add_tank(tank_b)
	
	var commands_a = [MoveCommand.create(tank_a.id, Direction.create(Direction.RIGHT))]
	var commands_b = [MoveCommand.create(tank_b.id, Direction.create(Direction.RIGHT))]
	
	var events_a = GameLoop.process_frame_static(state_a, commands_a)
	var events_b = GameLoop.process_frame_static(state_b, commands_b)
	
	var serialized_a = events_a.map(func(e): return JSON.stringify(e.to_dict()))
	var serialized_b = events_b.map(func(e): return JSON.stringify(e.to_dict()))
	
	assert_eq(serialized_a, serialized_b, "Events must serialize identically for deterministic remote sync")
