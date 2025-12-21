extends GutTest
## BDD Test Suite: Audio Playback on Game Events
## Tests that correct AudioStreamPlayer plays sound for each game event

const GameRoot3D = preload("res://scenes3d/game_root_3d.gd")
const GodotGameAdapter = preload("res://src/adapters/godot_game_adapter.gd")
const Tank3DScene = preload("res://scenes3d/tank_3d.tscn")

var game_root: Node
var adapter: GodotGameAdapter

func before_each():
	# Instantiate the game scene
	game_root = load("res://scenes3d/game_3d_ddd.tscn").instantiate()
	add_child_autofree(game_root)

	# Wait for _ready
	await wait_frames(1)

	# Get adapter reference
	adapter = game_root.adapter

	# Assert audio players are not null
	assert_not_null(game_root.background_music, "Background music player should not be null")
	assert_not_null(game_root.tank_move_sound, "Tank move sound player should not be null")
	assert_not_null(game_root.enemy_tank_move_sound, "Enemy tank move sound player should not be null")
	assert_not_null(game_root.tank_shoot_sound, "Tank shoot sound player should not be null")
	assert_not_null(game_root.tank_explosion_sound, "Tank explosion sound player should not be null")
	assert_not_null(game_root.bullet_hit_sound, "Bullet hit sound player should not be null")
	assert_not_null(game_root.bullet_hit_tank_sound, "Bullet hit tank sound player should not be null")
	assert_not_null(game_root.stage_complete_sound, "Stage complete sound player should not be null")
	assert_not_null(game_root.game_over_sound, "Game over sound player should not be null")
	assert_not_null(game_root.bullet_fire_enemy_sound, "Bullet fire enemy sound player should not be null")
	assert_not_null(game_root.bullet_hit_wall_sound, "Bullet hit wall sound player should not be null")
	assert_not_null(game_root.enemy_spawn_sound, "Enemy spawn sound player should not be null")
	assert_not_null(game_root.life_lost_sound, "Life lost sound player should not be null")
	assert_not_null(game_root.pause_sound, "Pause sound player should not be null")
	assert_not_null(game_root.powerup_appear_sound, "Powerup appear sound player should not be null")
	assert_not_null(game_root.powerup_collect_sound, "Powerup collect sound player should not be null")
	assert_not_null(game_root.base_hit_sound, "Base hit sound player should not be null")
	assert_not_null(game_root.level_start_sound, "Level start sound player should not be null")
	assert_not_null(game_root.title_screen_music, "Title screen music player should not be null")

	# Stop all audio players to ensure clean state
	game_root.tank_move_sound.stop()
	game_root.enemy_tank_move_sound.stop()
	game_root.tank_shoot_sound.stop()
	game_root.tank_explosion_sound.stop()
	game_root.bullet_hit_sound.stop()
	game_root.bullet_hit_tank_sound.stop()
	game_root.stage_complete_sound.stop()
	game_root.game_over_sound.stop()
	game_root.bullet_fire_enemy_sound.stop()
	game_root.bullet_hit_wall_sound.stop()
	game_root.enemy_spawn_sound.stop()
	game_root.life_lost_sound.stop()
	game_root.pause_sound.stop()
	game_root.powerup_appear_sound.stop()
	game_root.powerup_collect_sound.stop()
	game_root.base_hit_sound.stop()

	# Stop all audio players to ensure clean state
	game_root.tank_move_sound.stop()
	game_root.enemy_tank_move_sound.stop()
	game_root.tank_shoot_sound.stop()
	game_root.tank_explosion_sound.stop()
	game_root.bullet_hit_sound.stop()
	game_root.bullet_hit_tank_sound.stop()
	game_root.stage_complete_sound.stop()
	game_root.game_over_sound.stop()
	game_root.bullet_fire_enemy_sound.stop()
	game_root.bullet_hit_wall_sound.stop()
	game_root.enemy_spawn_sound.stop()
	game_root.life_lost_sound.stop()
	game_root.pause_sound.stop()
	game_root.powerup_appear_sound.stop()
	game_root.powerup_collect_sound.stop()
	game_root.base_hit_sound.stop()

func after_each():
	# Clean up tanks added during tests
	for tank_id in game_root.tank_nodes.keys():
		var tank_node = game_root.tank_nodes[tank_id]
		if tank_node:
			tank_node.queue_free()
	game_root.tank_nodes.clear()
	game_root.player_tank_id = ""
	
	# Clean up other entities if needed
	# Add similar cleanup logic for bullets or other nodes if applicable

func _register_tank(tank_id: String, is_player: bool = false) -> Node3D:
	var tank_node: Node3D = Tank3DScene.instantiate()
	tank_node.name = "Tank_%s" % tank_id
	game_root.tank_nodes[tank_id] = tank_node
	game_root.tanks_container.add_child(tank_node)
	if is_player:
		game_root.player_tank_id = tank_id
	return tank_node

# ============================================================================
# Epic: Tank Movement Audio
# ============================================================================

func test_given_player_tank_exists_when_tank_moves_then_tank_move_sound_plays():
	# Given: Player tank exists
	_register_tank("player_1", true)
	
	# Debug: Check if audio player exists
	assert_not_null(game_root.tank_move_sound, "tank_move_sound should not be null")

	# When: Tank moved signal emitted for player tank
	adapter.emit_signal("tank_moved", "player_1", Vector2(5, 5), Vector2(5, 6), 0)

	# Then: Tank move sound should play
	assert_true(game_root.tank_move_sound.playing)

func test_given_enemy_tank_exists_when_tank_moves_then_enemy_tank_move_sound_plays():
	# Given: Enemy tank exists (not player)
	_register_tank("player_1", true)
	_register_tank("enemy_1")
	
	# Debug: Check if audio player exists
	assert_not_null(game_root.enemy_tank_move_sound, "enemy_tank_move_sound should not be null")

	# When: Tank moved signal emitted for enemy tank
	adapter.emit_signal("tank_moved", "enemy_1", Vector2(10, 10), Vector2(10, 11), 0)

	# Wait for signal processing
	await wait_frames(1)

	# Then: Enemy tank move sound should play
	assert_true(game_root.enemy_tank_move_sound.playing)

# ============================================================================
# Epic: Tank Spawning Audio
# ============================================================================

func test_given_game_running_when_enemy_tank_spawned_then_enemy_spawn_sound_plays():
	# Given: Game is running
	# When: Tank spawned signal emitted for enemy
	adapter.emit_signal("tank_spawned", "enemy_1", Vector2(10, 10), 1, 0) # 1 = ENEMY_BASIC

	# Wait for signal processing
	await wait_frames(1)

	# Then: Enemy spawn sound should play
	assert_true(game_root.enemy_spawn_sound.playing)

# ============================================================================
# Epic: Tank Shooting Audio
# ============================================================================

func test_given_game_running_when_bullet_fired_then_tank_shoot_sound_plays():
	# Given: Game is running (adapter connected)
	_register_tank("player_1", true)
	# When: Bullet fired signal emitted
	adapter.emit_signal("bullet_fired", "bullet_1", Vector2(5, 5), 0, "player_1")

	# Wait for signal processing
	await wait_frames(1)

	# Then: Tank shoot sound should play
	assert_true(game_root.tank_shoot_sound.playing)

func test_given_game_running_when_bullet_fired_by_enemy_then_bullet_fire_enemy_sound_plays():
	# Given: Game is running
	# When: Bullet fired signal emitted by enemy
	adapter.emit_signal("bullet_fired", "bullet_1", Vector2(5, 5), 0, "enemy_1")

	# Wait for signal processing
	await wait_frames(1)

	# Then: Bullet fire enemy sound should play
	assert_true(game_root.bullet_fire_enemy_sound.playing)

# ============================================================================
# Epic: Tank Destruction Audio
# ============================================================================

func test_given_tank_exists_when_tank_destroyed_then_tank_explosion_sound_plays():
	# Given: Tank exists in the scene
	var tank_node = load("res://scenes3d/tank_3d.tscn").instantiate()
	tank_node.name = "Tank_player_1"
	game_root.tank_nodes["player_1"] = tank_node
	add_child_autofree(tank_node)

	# When: Tank destroyed signal emitted
	adapter.emit_signal("tank_destroyed", "player_1", Vector2(5, 5))

	# Wait for signal processing
	await wait_frames(1)

	# Then: Tank explosion sound should play
	assert_true(game_root.tank_explosion_sound.playing)

func test_given_tank_exists_when_tank_damaged_then_bullet_hit_tank_sound_plays():
	# Given: Tank exists in the scene
	var tank_node = load("res://scenes3d/tank_3d.tscn").instantiate()
	tank_node.name = "Tank_player_1"
	game_root.tank_nodes["player_1"] = tank_node
	add_child_autofree(tank_node)

	# When: Tank damaged signal emitted
	adapter.emit_signal("tank_damaged", "player_1", 1, 3, 2)

	# Wait for signal processing
	await wait_frames(1)

	# Then: Bullet hit tank sound should play
	assert_true(game_root.bullet_hit_tank_sound.playing)

func test_given_player_tank_exists_when_player_tank_destroyed_then_life_lost_sound_plays():
	# Given: Player tank exists
	game_root.player_tank_id = "player_1"
	var tank_node = load("res://scenes3d/tank_3d.tscn").instantiate()
	tank_node.name = "Tank_player_1"
	game_root.tank_nodes["player_1"] = tank_node
	add_child_autofree(tank_node)

	# When: Player tank destroyed signal emitted
	adapter.emit_signal("tank_destroyed", "player_1", Vector2(5, 5))

	# Wait for signal processing
	await wait_frames(1)

	# Then: Life lost sound should play
	assert_true(game_root.life_lost_sound.playing)

# ============================================================================
# Epic: Bullet Hit Audio
# ============================================================================

func test_given_bullet_exists_when_bullet_destroyed_then_bullet_hit_sound_plays():
	# Given: Bullet exists in the scene
	var bullet_node = load("res://scenes3d/bullet_3d.tscn").instantiate()
	bullet_node.name = "Bullet_bullet_1"
	game_root.bullet_nodes["bullet_1"] = bullet_node
	add_child_autofree(bullet_node)

	# When: Bullet destroyed signal emitted
	adapter.emit_signal("bullet_destroyed", "bullet_1", Vector2(5, 5))

	# Wait for signal processing
	await wait_frames(1)

	# Then: Bullet hit sound should play
	assert_true(game_root.bullet_hit_wall_sound.playing)

# ============================================================================
# Epic: Stage Complete Audio
# ============================================================================

func test_given_game_running_when_stage_complete_then_stage_complete_sound_plays():
	# Given: Game is running
	# When: Stage complete signal emitted
	adapter.emit_signal("stage_complete")

	# Wait for signal processing
	await wait_frames(1)

	# Then: Stage complete sound should play
	assert_true(game_root.stage_complete_sound.playing)

# ============================================================================
# Epic: Game Over Audio
# ============================================================================

func test_given_game_running_when_game_over_then_game_over_sound_plays():
	# Given: Game is running
	# When: Game over signal emitted
	adapter.emit_signal("game_over", "test_reason")

	# Wait for signal processing
	await wait_frames(1)

	# Then: Game over sound should play
	assert_true(game_root.game_over_sound.playing)

func test_given_game_running_when_game_over_base_hit_then_base_hit_sound_plays():
	# Given: Game is running
	# When: Game over signal emitted with base reason
	adapter.emit_signal("game_over", "base destroyed")

	# Wait for signal processing
	await wait_frames(1)

	# Then: Base hit sound should play
	assert_true(game_root.base_hit_sound.playing)