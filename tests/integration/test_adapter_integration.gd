extends GutTest
## BDD Integration Tests for DDD Adapter Layer
## Tests the adapter layer that bridges pure domain logic with Godot presentation

const GameState = preload("res://src/domain/aggregates/game_state.gd")
const StageState = preload("res://src/domain/aggregates/stage_state.gd")
const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const BulletEntity = preload("res://src/domain/entities/bullet_entity.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")
const Health = preload("res://src/domain/value_objects/health.gd")
const TankStats = preload("res://src/domain/value_objects/tank_stats.gd")
const MoveCommand = preload("res://src/domain/commands/move_command.gd")
const FireCommand = preload("res://src/domain/commands/fire_command.gd")
const GodotGameAdapter = preload("res://src/adapters/godot_game_adapter.gd")
const InputAdapter = preload("res://src/adapters/input_adapter.gd")

var adapter: GodotGameAdapter
var game_state: GameState
var stage: StageState

func before_each():
	# Create test stage (26x26 grid)
	stage = StageState.create(1, 26, 26)
	
	# Create test game state
	game_state = GameState.create(stage, 3)
	
	# Create adapter
	adapter = GodotGameAdapter.new()
	add_child_autofree(adapter)
	
	# Initialize adapter with game state
	adapter.initialize(game_state)

func after_each():
	if adapter:
		adapter.queue_free()

## ============================================================================
## Epic: Adapter Initialization
## ============================================================================

func test_given_adapter_when_initialized_then_has_game_state():
	# Given: Adapter is created in before_each
	# When: Adapter is initialized
	# Then: Adapter has valid game state
	assert_not_null(adapter.game_state, "Adapter should have game state")
	assert_eq(adapter.game_state, game_state, "Adapter should reference correct game state")

func test_given_adapter_when_initialized_then_starts_processing():
	# Given: Adapter is created
	# When: Adapter is initialized
	# Then: Physics processing should be enabled
	assert_true(adapter.is_physics_processing(), "Adapter should enable physics processing")

## ============================================================================
## Epic: Domain Event to Godot Signal Conversion
## ============================================================================

func test_given_tank_spawned_in_domain_when_synced_then_emits_godot_signal():
	# Given: Adapter is listening to domain events
	watch_signals(adapter)
	
	# When: A tank is spawned in domain
	var tank = TankEntity.create(
		"tank_1",
		TankEntity.Type.PLAYER,
		Position.create(5, 5),
		Direction.create(Direction.UP)
	)
	game_state.add_tank(tank)
	adapter.sync_state_to_presentation()
	
	# Then: tank_spawned signal should be emitted
	assert_signal_emitted(adapter, "tank_spawned", "Should emit tank_spawned signal")

func test_given_tank_moved_in_domain_when_synced_then_emits_moved_signal():
	# Given: Tank exists in game state
	var tank = TankEntity.create(
		"tank_1",
		TankEntity.Type.PLAYER,
		Position.create(5, 5),
		Direction.create(Direction.UP)
	)
	game_state.add_tank(tank)
	adapter.sync_state_to_presentation()
	watch_signals(adapter)
	
	# When: Tank moves in domain
	tank.position = Position.create(5, 4) # Move up
	adapter.sync_state_to_presentation()
	
	# Then: tank_moved signal should be emitted
	assert_signal_emitted(adapter, "tank_moved", "Should emit tank_moved signal")

func test_given_tank_destroyed_in_domain_when_synced_then_emits_destroyed_signal():
	# Given: Tank exists in game state
	var tank = TankEntity.create(
		"tank_1",
		TankEntity.Type.PLAYER,
		Position.create(5, 5),
		Direction.create(Direction.UP)
	)
	game_state.add_tank(tank)
	adapter.sync_state_to_presentation()
	watch_signals(adapter)
	
	# When: Tank is destroyed
	game_state.remove_tank(tank.id)
	adapter.sync_state_to_presentation()
	
	# Then: tank_destroyed signal should be emitted
	assert_signal_emitted(adapter, "tank_destroyed", "Should emit tank_destroyed signal")

func test_given_bullet_fired_in_domain_when_synced_then_emits_fired_signal():
	# Given: Adapter is listening
	watch_signals(adapter)
	
	# When: A bullet is fired in domain
	var bullet = BulletEntity.create(
		"bullet_1",
		"tank_1",
		Position.create(5, 5),
		Direction.create(Direction.UP),
		4, # speed
		1 # damage
	)
	game_state.add_bullet(bullet)
	adapter.sync_state_to_presentation()
	
	# Then: bullet_fired signal should be emitted
	assert_signal_emitted(adapter, "bullet_fired", "Should emit bullet_fired signal")

func test_given_bullet_destroyed_in_domain_when_synced_then_emits_destroyed_signal():
	# Given: Bullet exists in game state
	var bullet = BulletEntity.create(
		"bullet_1",
		"tank_1",
		Position.create(5, 5),
		Direction.create(Direction.UP),
		4, # speed
		1 # damage
	)
	game_state.add_bullet(bullet)
	adapter.sync_state_to_presentation()
	watch_signals(adapter)
	
	# When: Bullet is destroyed
	game_state.remove_bullet(bullet.id)
	adapter.sync_state_to_presentation()
	
	# Then: bullet_destroyed signal should be emitted
	assert_signal_emitted(adapter, "bullet_destroyed", "Should emit bullet_destroyed signal")

## ============================================================================
## Epic: Input Conversion to Commands
## ============================================================================

func test_given_player_presses_up_when_converted_then_creates_move_command():
	# Given: Input adapter
	var input_adapter = InputAdapter.new()
	var tank_id = "player_1"
	
	# When: Player presses up
	Input.action_press("move_up")
	var commands = input_adapter.get_commands_for_frame(tank_id, 0)
	Input.action_release("move_up")
	
	# Then: Should create MoveCommand with UP direction
	assert_gt(commands.size(), 0, "Should create at least one command")
	var move_cmd = commands[0]
	assert_true(move_cmd is MoveCommand, "Should be a MoveCommand")
	assert_eq(move_cmd.direction.value, Direction.UP, "Should move UP")

func test_given_player_presses_down_when_converted_then_creates_move_command():
	# Given: Input adapter
	var input_adapter = InputAdapter.new()
	var tank_id = "player_1"
	
	# When: Player presses down
	Input.action_press("move_down")
	var commands = input_adapter.get_commands_for_frame(tank_id, 0)
	Input.action_release("move_down")
	
	# Then: Should create MoveCommand with DOWN direction
	assert_gt(commands.size(), 0, "Should create at least one command")
	var move_cmd = commands[0]
	assert_true(move_cmd is MoveCommand, "Should be a MoveCommand")
	assert_eq(move_cmd.direction.value, Direction.DOWN, "Should move DOWN")

func test_given_player_presses_left_when_converted_then_creates_move_command():
	# Given: Input adapter
	var input_adapter = InputAdapter.new()
	var tank_id = "player_1"
	
	# When: Player presses left
	Input.action_press("move_left")
	var commands = input_adapter.get_commands_for_frame(tank_id, 0)
	Input.action_release("move_left")
	
	# Then: Should create MoveCommand with LEFT direction
	assert_gt(commands.size(), 0, "Should create at least one command")
	var move_cmd = commands[0]
	assert_true(move_cmd is MoveCommand, "Should be a MoveCommand")
	assert_eq(move_cmd.direction.value, Direction.LEFT, "Should move LEFT")

func test_given_player_presses_right_when_converted_then_creates_move_command():
	# Given: Input adapter
	var input_adapter = InputAdapter.new()
	var tank_id = "player_1"
	
	# When: Player presses right
	Input.action_press("move_right")
	var commands = input_adapter.get_commands_for_frame(tank_id, 0)
	Input.action_release("move_right")
	
	# Then: Should create MoveCommand with RIGHT direction
	assert_gt(commands.size(), 0, "Should create at least one command")
	var move_cmd = commands[0]
	assert_true(move_cmd is MoveCommand, "Should be a MoveCommand")
	assert_eq(move_cmd.direction.value, Direction.RIGHT, "Should move RIGHT")

func test_given_player_presses_fire_when_converted_then_creates_fire_command():
	# Given: Input adapter
	var input_adapter = InputAdapter.new()
	var tank_id = "player_1"
	
	# When: Player presses fire
	Input.action_press("fire")
	var commands = input_adapter.get_commands_for_frame(tank_id, 0)
	Input.action_release("fire")
	
	# Then: Should create FireCommand
	assert_gt(commands.size(), 0, "Should create at least one command")
	var has_fire = false
	for cmd in commands:
		if cmd is FireCommand:
			has_fire = true
			break
	assert_true(has_fire, "Should have a FireCommand")

func test_given_no_input_when_converted_then_returns_empty_commands():
	# Given: Input adapter with no input
	var input_adapter = InputAdapter.new()
	var tank_id = "player_1"
	
	# When: Getting commands with no input
	var commands = input_adapter.get_commands_for_frame(tank_id, 0)
	
	# Then: Should return empty array
	assert_eq(commands.size(), 0, "Should return empty commands array")

## ============================================================================
## Epic: Frame-Based Processing
## ============================================================================

func test_given_adapter_in_physics_process_when_frame_advances_then_processes_game_loop():
	# Given: Adapter with game state
	var initial_frame = game_state.frame
	
	# When: Physics process is called (simulating one frame)
	adapter._physics_process(1.0 / 60.0)
	
	# Then: Game state frame should advance
	assert_eq(game_state.frame, initial_frame + 1, "Frame should advance by 1")

func test_given_tank_in_game_when_physics_process_then_syncs_to_presentation():
	# Given: Tank in game state
	var tank = TankEntity.create(
		"tank_1",
		TankEntity.Type.PLAYER,
		Position.create(5, 5),
		Direction.create(Direction.UP)
	)
	game_state.add_tank(tank)
	
	# When: Physics process runs
	adapter._physics_process(1.0 / 60.0)
	
	# Then: Adapter should track the tank
	assert_true(adapter.tracked_tanks.has("tank_1"), "Adapter should track tank_1")

## ============================================================================
## Epic: Domain Position to Godot Position Conversion
## ============================================================================

func test_given_domain_position_when_converted_then_maps_to_godot_coordinates():
	# Given: Domain position (tile coordinates)
	var domain_pos = Position.create(5, 10)
	
	# When: Converting to Godot position
	var godot_pos = adapter.domain_position_to_godot(domain_pos)
	
	# Then: Should convert correctly (assuming TILE_SIZE constant)
	assert_not_null(godot_pos, "Should return a position")
	# Exact values depend on TILE_SIZE constant in adapter
	assert_true(godot_pos is Vector2, "Should return Vector2")

func test_given_direction_when_converted_then_maps_to_rotation():
	# Given: Domain direction
	var dir_up = Direction.create(Direction.UP)
	var dir_down = Direction.create(Direction.DOWN)
	var dir_left = Direction.create(Direction.LEFT)
	var dir_right = Direction.create(Direction.RIGHT)
	
	# When: Converting to rotation
	var rot_up = adapter.direction_to_rotation(dir_up)
	var rot_down = adapter.direction_to_rotation(dir_down)
	var rot_left = adapter.direction_to_rotation(dir_left)
	var rot_right = adapter.direction_to_rotation(dir_right)
	
	# Then: Rotations should be different
	assert_ne(rot_up, rot_down, "UP and DOWN should have different rotations")
	assert_ne(rot_left, rot_right, "LEFT and RIGHT should have different rotations")

## ============================================================================
## Epic: Entity Lifecycle Management
## ============================================================================

func test_given_new_tank_when_synced_then_creates_tracking_entry():
	# Given: Empty adapter
	assert_eq(adapter.tracked_tanks.size(), 0, "Should start with no tracked tanks")
	
	# When: Adding tank to game state and syncing
	var tank = TankEntity.create(
		"tank_1",
		TankEntity.Type.PLAYER,
		Position.create(5, 5),
		Direction.create(Direction.UP)
	)
	game_state.add_tank(tank)
	adapter.sync_state_to_presentation()
	
	# Then: Adapter should track the tank
	assert_eq(adapter.tracked_tanks.size(), 1, "Should track one tank")
	assert_true(adapter.tracked_tanks.has("tank_1"), "Should track tank_1")

func test_given_removed_tank_when_synced_then_removes_tracking_entry():
	# Given: Tank exists and is tracked
	var tank = TankEntity.create(
		"tank_1",
		TankEntity.Type.PLAYER,
		Position.create(5, 5),
		Direction.create(Direction.UP)
	)
	game_state.add_tank(tank)
	adapter.sync_state_to_presentation()
	assert_eq(adapter.tracked_tanks.size(), 1, "Should have one tracked tank")
	
	# When: Removing tank and syncing
	game_state.remove_tank("tank_1")
	adapter.sync_state_to_presentation()
	
	# Then: Adapter should no longer track the tank
	assert_eq(adapter.tracked_tanks.size(), 0, "Should have no tracked tanks")
	assert_false(adapter.tracked_tanks.has("tank_1"), "Should not track tank_1")

func test_given_new_bullet_when_synced_then_creates_tracking_entry():
	# Given: Empty adapter
	assert_eq(adapter.tracked_bullets.size(), 0, "Should start with no tracked bullets")
	
	# When: Adding bullet to game state and syncing
	var bullet = BulletEntity.create(
		"bullet_1",
		"tank_1",
		Position.create(5, 5),
		Direction.create(Direction.UP),
		4, # speed
		1 # damage
	)
	game_state.add_bullet(bullet)
	adapter.sync_state_to_presentation()
	
	# Then: Adapter should track the bullet
	assert_eq(adapter.tracked_bullets.size(), 1, "Should track one bullet")
	assert_true(adapter.tracked_bullets.has("bullet_1"), "Should track bullet_1")

func test_given_removed_bullet_when_synced_then_removes_tracking_entry():
	# Given: Bullet exists and is tracked
	var bullet = BulletEntity.create(
		"bullet_1",
		"tank_1",
		Position.create(5, 5),
		Direction.create(Direction.UP),
		4, # speed
		1 # damage
	)
	game_state.add_bullet(bullet)
	adapter.sync_state_to_presentation()
	assert_eq(adapter.tracked_bullets.size(), 1, "Should have one tracked bullet")
	
	# When: Removing bullet and syncing
	game_state.remove_bullet("bullet_1")
	adapter.sync_state_to_presentation()
	
	# Then: Adapter should no longer track the bullet
	assert_eq(adapter.tracked_bullets.size(), 0, "Should have no tracked bullets")
	assert_false(adapter.tracked_bullets.has("bullet_1"), "Should not track bullet_1")
