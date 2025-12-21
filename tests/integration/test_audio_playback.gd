extends GutTest
## BDD Integration Tests for Audio Playback
## Tests that correct sounds play on game events

const GameRoot3D = preload("res://scenes3d/game_root_3d.gd")
const GodotGameAdapter = preload("res://src/adapters/godot_game_adapter.gd")
const GameStateEnum = preload("res://src/domain/value_objects/game_state_enum.gd")
const GameState = preload("res://src/domain/aggregates/game_state.gd")
const StageState = preload("res://src/domain/aggregates/stage_state.gd")
const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")

var scene: Node3D
var adapter: GodotGameAdapter
var game_root: GameRoot3D

func before_each():
	# Load and instantiate the scene
	var scene_resource = load("res://scenes3d/game_3d_ddd.tscn")
	scene = scene_resource.instantiate()
	add_child_autofree(scene)

	# Wait for scene to be fully ready
	await wait_frames(1)

	# Get references
	adapter = scene.get_node("GodotGameAdapter")
	game_root = scene

func after_each():
	if scene:
		scene.queue_free()

# ============================================================================
# Given Steps
# ============================================================================

func given_the_game_is_running():
	# Start the game
	game_root._state_machine.transition_to(GameStateEnum.State.PLAYING)
	game_root._start_new_game()
	await wait_physics_frames(5)

func given_the_player_tank_exists():
	# Ensure player tank is spawned
	assert_not_null(game_root.player_tank_id, "Player tank should exist")
	assert_true(game_root.tank_nodes.has(game_root.player_tank_id), "Player tank node should exist")

func given_an_enemy_tank_exists():
	# Spawn an enemy tank if needed
	var enemy_id = "enemy_1"
	if not game_root.tank_nodes.has(enemy_id):
		# Create enemy tank in domain
		var enemy_tank = TankEntity.create(
			enemy_id,
			TankEntity.Type.ENEMY_BASIC,
			Position.create(10, 10),
			Direction.create(Direction.DOWN)
		)
		adapter.game_state.add_tank(enemy_tank)
		adapter.sync_state_to_presentation()
		await wait_frames(1)

	assert_true(game_root.tank_nodes.has(enemy_id), "Enemy tank should exist")

func given_a_tank_exists():
	given_the_player_tank_exists()

func given_a_bullet_exists():
	# Fire a bullet from player tank
	var bullet_id = "bullet_1"
	if not game_root.bullet_nodes.has(bullet_id):
		# Simulate bullet firing
		adapter.emit_signal("bullet_fired", bullet_id, Vector2(5, 5), Direction.DOWN, game_root.player_tank_id)
		await wait_frames(1)

	assert_true(game_root.bullet_nodes.has(bullet_id), "Bullet should exist")

# ============================================================================
# When Steps
# ============================================================================

func when_the_player_tank_moves():
	# Emit tank_moved signal for player tank
	var old_pos = Vector2(5, 5)
	var new_pos = Vector2(5, 4)
	adapter.emit_signal("tank_moved", game_root.player_tank_id, old_pos, new_pos, Direction.UP)
	await wait_frames(1)

func when_the_enemy_tank_moves():
	# Emit tank_moved signal for enemy tank
	var enemy_id = "enemy_1"
	var old_pos = Vector2(10, 10)
	var new_pos = Vector2(10, 11)
	adapter.emit_signal("tank_moved", enemy_id, old_pos, new_pos, Direction.DOWN)
	await wait_frames(1)

func when_the_player_tank_fires_a_bullet():
	# Emit bullet_fired signal
	var bullet_id = "bullet_2"
	var position = Vector2(5, 5)
	adapter.emit_signal("bullet_fired", bullet_id, position, Direction.UP, game_root.player_tank_id)
	await wait_frames(1)

func when_the_tank_is_destroyed():
	# Emit tank_destroyed signal
	var tank_id = game_root.player_tank_id
	var position = Vector2(5, 5)
	adapter.emit_signal("tank_destroyed", tank_id, position)
	await wait_frames(1)

func when_the_bullet_hits_a_tank():
	# Emit bullet_destroyed signal (assuming it hit a tank)
	var bullet_id = "bullet_1"
	var position = Vector2(10, 10)
	adapter.emit_signal("bullet_destroyed", bullet_id, position)
	await wait_frames(1)

func when_the_stage_is_completed():
	# Emit stage_complete signal
	adapter.emit_signal("stage_complete")
	await wait_frames(1)

func when_the_game_ends():
	# Emit game_over signal
	adapter.emit_signal("game_over", "test_reason")
	await wait_frames(1)

# ============================================================================
# Then Steps
# ============================================================================

func then_the_tank_move_sound_should_play():
	assert_true(game_root.tank_move_sound.playing, "Tank move sound should be playing")

func then_the_enemy_tank_move_sound_should_play():
	# Note: Currently only player tank move sound is implemented
	# This test will fail until enemy move sound is added
	if game_root.has_node("Audio/SoundEffects/EnemyTankMove"):
		var enemy_move_sound = game_root.get_node("Audio/SoundEffects/EnemyTankMove")
		assert_true(enemy_move_sound.playing, "Enemy tank move sound should be playing")
	else:
		fail_test("Enemy tank move sound not implemented yet")

func then_the_tank_shoot_sound_should_play():
	assert_true(game_root.tank_shoot_sound.playing, "Tank shoot sound should be playing")

func then_the_tank_explosion_sound_should_play():
	assert_true(game_root.tank_explosion_sound.playing, "Tank explosion sound should be playing")

func then_the_bullet_hit_sound_should_play():
	assert_true(game_root.bullet_hit_sound.playing, "Bullet hit sound should be playing")

func then_the_stage_complete_sound_should_play():
	assert_true(game_root.stage_complete_sound.playing, "Stage complete sound should be playing")

func then_the_game_over_sound_should_play():
	assert_true(game_root.game_over_sound.playing, "Game over sound should be playing")