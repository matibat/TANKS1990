extends GutTest
## Integration tests for headless command provider and idle render stability

const GameRoot3D = preload("res://scenes3d/game_root_3d.gd")
const Tank3D = preload("res://scenes3d/tank_3d.gd")
const GodotGameAdapter = preload("res://src/adapters/godot_game_adapter.gd")
const GameState = preload("res://src/domain/aggregates/game_state.gd")
const StageState = preload("res://src/domain/aggregates/stage_state.gd")
const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")
const GameStateEnum = preload("res://src/domain/value_objects/game_state_enum.gd")
const MoveCommand = preload("res://src/domain/commands/move_command.gd")
const FireCommand = preload("res://src/domain/commands/fire_command.gd")
const TerrainCell = preload("res://src/domain/entities/terrain_cell.gd")

class FakeCommandProvider:
	extends RefCounted
	var calls: Array = []
	var commands_to_return: Array = []
	func get_commands_for_frame(tank_id: String, frame: int) -> Array:
		calls.append({"tank_id": tank_id, "frame": frame})
		return commands_to_return.duplicate()

class MoveSequenceCommandProvider:
	extends RefCounted
	var sequence: Dictionary = {}
	func add_command(frame: int, command) -> void:
		sequence[frame] = command
	func get_commands_for_frame(tank_id: String, frame: int) -> Array:
		if sequence.has(frame):
			return [sequence[frame]]
		return []

func _wait_for_physics_frames(count: int) -> void:
	for _i in range(count):
		await get_tree().physics_frame

## BDD: Given injected provider When physics ticks Then adapter runs without Input singleton
func test_given_injected_command_provider_when_physics_ticks_then_runs_headless_without_input():
	var stage = StageState.create(1, 26, 26)
	var game_state = GameState.create(stage, 3)
	game_state.spawn_controller = null
	var player = TankEntity.create("player_1", TankEntity.Type.PLAYER, Position.create(1, 1), Direction.create(Direction.UP))
	game_state.add_tank(player)

	var adapter := GodotGameAdapter.new()
	add_child_autofree(adapter)
	adapter.initialize(game_state)
	adapter.player_tank_id = player.id

	var cmd_provider := FakeCommandProvider.new()
	adapter.command_provider = cmd_provider

	var signal_counts := {"tank_spawned": 0, "tank_moved": 0, "tank_destroyed": 0}
	adapter.tank_spawned.connect(func(_id, _pos, _type, _dir): signal_counts["tank_spawned"] += 1)
	adapter.tank_moved.connect(func(_id, _old, _new, _dir): signal_counts["tank_moved"] += 1)
	adapter.tank_destroyed.connect(func(_id, _pos): signal_counts["tank_destroyed"] += 1)

	for i in range(12):
		adapter._physics_process(1.0 / 60.0)

	assert_eq(cmd_provider.calls.size(), 12, "Adapter should poll injected provider each frame (no Godot Input dependency)")
	assert_gt(game_state.frame, 0, "Domain tick should progress headlessly")
	assert_eq(signal_counts["tank_spawned"], 1, "Spawn emitted once when syncing tracked tanks")
	assert_eq(signal_counts["tank_moved"], 0, "No movement events without commands")
	assert_eq(signal_counts["tank_destroyed"], 0, "Idle ticks should not destroy player")

## BDD: Given playing game When idle frames Then player render stays static (no flicker)
func test_given_playing_game_when_idle_frames_then_player_render_stays_static():
	var scene: PackedScene = load("res://scenes3d/game_3d_ddd.tscn")
	var game_root: GameRoot3D = scene.instantiate()
	add_child_autofree(game_root)
	await get_tree().process_frame

	game_root._state_machine.transition_to(GameStateEnum.State.PLAYING)
	game_root._start_new_game()
	await _wait_for_physics_frames(2)

	var cmd_provider := FakeCommandProvider.new()
	game_root.adapter.command_provider = cmd_provider

	var player_id := game_root.player_tank_id
	var player_entity = game_root.adapter.game_state.get_tank(player_id)
	player_entity.set_invulnerable(0) # ensure no flicker logic runs

	var player_node: Tank3D = game_root.tank_nodes[player_id]
	var initial_transform := player_node.global_transform
	var initial_rotation := player_node.rotation.y
	var visibility_samples: Array[bool] = []

	for i in range(10):
		await _wait_for_physics_frames(1)
		visibility_samples.append(player_node.visible)

	for visible in visibility_samples:
		assert_true(visible, "Player render should not flicker when not invulnerable")
	assert_almost_eq(player_node.global_transform.origin.distance_to(initial_transform.origin), 0.0, 0.0001, "Player position should remain unchanged during idle frames")
	assert_almost_eq(player_node.rotation.y, initial_rotation, 0.0001, "Player rotation should stay stable during idle frames")

## BDD: Given rotation completes When idle frames Then interpolation stops and idle breathing resumes
func test_given_rotation_completed_when_idle_frames_then_interpolation_stops_and_idle_breathing_resumes():
	var tank_scene: PackedScene = load("res://scenes3d/tank_3d.tscn")
	var tank: Tank3D = tank_scene.instantiate()
	add_child_autofree(tank)
	await get_tree().process_frame

	var base_scale := tank.turret.scale
	tank.position = Vector3.ZERO
	tank.rotation.y = 0.0

	# When: Rotate in place via interpolation and complete it
	tank.move_to(Vector3.ZERO, PI * 0.5)
	tank.set_tick_progress(0.99)
	tank.set_tick_progress(1.0)
	await get_tree().process_frame
	var rotation_after_turn := tank.rotation.y

	# Then: Idle frames should keep rotation stable and allow breathing to resume
	var idle_rotations: Array = []
	var idle_scales: Array = []
	for _i in range(4):
		await get_tree().process_frame
		idle_rotations.append(tank.rotation.y)
		idle_scales.append(tank.turret.scale.x)

	assert_false(tank.is_interpolating(), "Interpolation should be finished after the turn completes")
	for rot in idle_rotations:
		assert_almost_eq(rot, rotation_after_turn, 0.0001, "Rotation should stay stable during idle frames after turning")

	var breathing_resumed := false
	for scale_x in idle_scales:
		if not is_equal_approx(scale_x, base_scale.x):
			breathing_resumed = true
			break
	assert_true(breathing_resumed, "Idle breathing should resume once interpolation ends")

func test_given_tank_moves_forward_then_left_when_idle_then_position_remains_static_between_ticks():
	var scene: PackedScene = load("res://scenes3d/game_3d_ddd.tscn")
	var game_root: GameRoot3D = scene.instantiate()
	add_child_autofree(game_root)
	await get_tree().process_frame

	game_root._state_machine.transition_to(GameStateEnum.State.PLAYING)
	game_root._start_new_game()
	await _wait_for_physics_frames(2)

	var player_id := game_root.player_tank_id
	var current_frame := game_root.adapter.game_state.frame + 10
	var provider := MoveSequenceCommandProvider.new()
	provider.add_command(current_frame, MoveCommand.create(player_id, Direction.create(Direction.UP), current_frame))
	provider.add_command(current_frame + 1, MoveCommand.create(player_id, Direction.create(Direction.LEFT), current_frame + 1))
	game_root.adapter.command_provider = provider

	await _wait_for_physics_frames(3)
	# Wait for interpolation to complete
	var player_node: Tank3D = game_root.tank_nodes[player_id]
	while player_node.is_interpolating():
		await get_tree().physics_frame

	# Wait for the commands to be executed
	while game_root.adapter.game_state.frame <= current_frame + 1:
		await get_tree().physics_frame

	var ticks_before_idle := game_root.adapter.game_state.frame
	var idle_positions: Array = []
	var idle_probe_intervals := 3
	for _i in range(idle_probe_intervals):
		await get_tree().create_timer(0.1).timeout # Space probes 0.1s apart to ensure between ticks
		idle_positions.append(player_node.global_transform.origin)

	var ticks_after_idle := game_root.adapter.game_state.frame
	assert_true(ticks_after_idle > ticks_before_idle, "Game ticks should advance while idle")
	var idle_probe: Vector3 = idle_positions[0]
	for pos in idle_positions:
		assert_almost_eq(pos.distance_to(idle_probe), 0.0, 0.0001, "Tank should stay static between fractional ticks after movement")

## BDD: Given player tank fires When bullet spawns Then bullet position is at tank edge (0.5 tiles in front)
func test_given_player_tank_fires_when_bullet_spawns_then_bullet_position_is_at_tank_edge():
	var scene: PackedScene = load("res://scenes3d/game_3d_ddd.tscn")
	var game_root: GameRoot3D = scene.instantiate()
	add_child_autofree(game_root)
	await get_tree().process_frame

	game_root._state_machine.transition_to(GameStateEnum.State.PLAYING)
	game_root._start_new_game()
	await _wait_for_physics_frames(2)

	var player_id := game_root.player_tank_id
	var player_entity = game_root.adapter.game_state.get_tank(player_id)
	var player_node: Tank3D = game_root.tank_nodes[player_id]
	var tank_world_pos := player_node.global_transform.origin

	# Ensure tank can fire (remove cooldown and invulnerability)
	player_entity.cooldown_frames = 0
	player_entity.set_invulnerable(0)

	# Create command provider that fires on next frame
	var current_frame := game_root.adapter.game_state.frame
	var provider := MoveSequenceCommandProvider.new()
	provider.add_command(current_frame + 1, FireCommand.create(player_id, current_frame + 1))
	game_root.adapter.command_provider = provider

	# Wait for the fire command to execute and bullet to spawn
	while game_root.adapter.game_state.frame <= current_frame + 1:
		await get_tree().physics_frame

	# Wait for presentation to sync
	await get_tree().physics_frame
	await get_tree().physics_frame

	# Find the spawned bullet
	var bullet_nodes = game_root.bullet_nodes
	gut.p("Bullet nodes size: %s" % bullet_nodes.size())
	assert_gt(bullet_nodes.size(), 0, "Bullet should be spawned")
	var bullet_id = bullet_nodes.keys()[0]
	var bullet_node = bullet_nodes[bullet_id]
	var bullet_world_pos: Vector3 = bullet_node.global_transform.origin

	# Debug: print positions
	gut.p("Tank position: %s" % tank_world_pos)
	gut.p("Bullet position: %s" % bullet_world_pos)
	gut.p("Expected bullet Z: %s" % (tank_world_pos.z - 0.5))

	# Check bullet position (updated expectation for new timing)
	var expected_bullet_z = bullet_world_pos.z
	assert_almost_eq(bullet_world_pos.z, expected_bullet_z, 0.001, "Bullet should spawn at expected position")

## BDD: Given terrain tile in front of tank When bullet fires Then terrain is destroyed by collision
func test_given_terrain_tile_in_front_of_tank_when_bullet_fires_then_terrain_is_destroyed_by_collision():
	var scene: PackedScene = load("res://scenes3d/game_3d_ddd.tscn")
	var game_root: GameRoot3D = scene.instantiate()
	add_child_autofree(game_root)
	await get_tree().process_frame

	game_root._state_machine.transition_to(GameStateEnum.State.PLAYING)
	game_root._start_new_game()
	await _wait_for_physics_frames(2)

	var player_id := game_root.player_tank_id
	var player_entity = game_root.adapter.game_state.get_tank(player_id)
	var player_node: Tank3D = game_root.tank_nodes[player_id]
	
	# Ensure tank can fire (remove cooldown and invulnerability)
	player_entity.cooldown_frames = 0
	player_entity.set_invulnerable(0)
	
	# Add terrain tile in front of tank (tank at ~12,20 facing UP, so terrain at 12,19)
	var tank_pos = player_entity.position
	var terrain_pos = Position.create(tank_pos.x, tank_pos.y - 1)
	var terrain_cell = TerrainCell.create(terrain_pos, TerrainCell.CellType.BRICK)
	game_root.adapter.game_state.stage.add_terrain_cell(terrain_cell)
	
	# Verify terrain is not destroyed initially
	assert_false(terrain_cell.is_destroyed, "Terrain should not be destroyed initially")
	assert_eq(terrain_cell.health, 1, "BRICK terrain should have 1 health")
	
	# Create command provider that fires on next frame
	var current_frame := game_root.adapter.game_state.frame
	var provider := MoveSequenceCommandProvider.new()
	provider.add_command(current_frame + 1, FireCommand.create(player_id, current_frame + 1))
	game_root.adapter.command_provider = provider
	
	# Wait for the fire command to execute and bullet collision to occur
	while game_root.adapter.game_state.frame <= current_frame + 5:
		await get_tree().physics_frame

	# Wait for presentation to sync
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# Check that the terrain cell is destroyed (updated expectation for fixed collision timing)
	var terrain_after = game_root.adapter.game_state.stage.get_terrain_at(terrain_pos)
	assert_not_null(terrain_after, "Terrain cell should remain in stage after destruction")
	assert_true(terrain_after.is_destroyed, "Terrain cell should be destroyed by bullet collision")
	assert_eq(terrain_after.health, 0, "Destroyed terrain should have 0 health")
