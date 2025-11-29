extends GutTest
## BDD tests for player input isolation (enemies should not respond to keyboard)

var player_tank: Tank
var enemy_tank: Tank
var player_controller: PlayerController

func before_each():
	# Create player tank with controller
	player_tank = Tank.new()
	player_tank.tank_type = Tank.TankType.PLAYER
	player_tank.is_player = true
	player_tank.base_speed = 100.0
	add_child_autofree(player_tank)
	player_tank._ready()
	player_tank.spawn_timer = 0.0
	player_tank.current_state = Tank.State.IDLE
	
	player_controller = PlayerController.new()
	player_controller.tank = player_tank
	player_tank.add_child(player_controller)
	player_controller._ready()
	player_tank._complete_spawn()
	player_tank.invulnerability_timer = 0
	player_tank._end_invulnerability()
	
	# Create enemy tank WITHOUT controller
	enemy_tank = Tank.new()
	enemy_tank.tank_type = Tank.TankType.BASIC
	enemy_tank.is_player = false
	enemy_tank.base_speed = 50.0
	add_child_autofree(enemy_tank)
	enemy_tank._ready()
	enemy_tank.spawn_timer = 0.0
	enemy_tank._complete_spawn()
	enemy_tank.invulnerability_timer = 0
	enemy_tank._end_invulnerability()
	enemy_tank.current_state = Tank.State.IDLE

# ============================================================================
# FEATURE: Player Input Isolation
# As a player
# I want only my tank to respond to keyboard input
# So that I can't accidentally control enemy tanks
# ============================================================================

# SCENARIO: Player input moves only player tank, not enemies
func test_given_player_and_enemy_when_player_input_then_only_player_moves():
	# Given: Player and enemy at different positions
	player_tank.global_position = Vector2(100, 100)
	enemy_tank.global_position = Vector2(300, 300)
	var enemy_start_pos = enemy_tank.global_position
	
	# When: Directly move player tank up
	player_tank.move_in_direction(Tank.Direction.UP)
	
	# Run physics to process movement
	for i in range(10):
		player_tank._physics_process(0.016)
		await get_tree().physics_frame
	
	# Then: Player tank should have moved (at least one 8-pixel grid step)
	assert_ne(player_tank.global_position, Vector2(100.0, 100.0), "Player tank should move")
	assert_lt(player_tank.global_position.y, 100.0, "Player tank should move up")
	
	# And: Enemy tank should NOT have moved
	assert_eq(enemy_tank.global_position, enemy_start_pos, "Enemy tank should not move from player input")
	assert_eq(enemy_tank.velocity, Vector2.ZERO, "Enemy tank should have zero velocity")

# SCENARIO: Enemy tank has no PlayerController child
func test_given_enemy_tank_when_spawned_then_has_no_player_controller():
	# Given/When: Enemy tank created (in before_each)
	
	# Then: Enemy should not have PlayerController as child
	var has_controller = false
	for child in enemy_tank.get_children():
		if child is PlayerController:
			has_controller = true
			break
	
	assert_false(has_controller, "Enemy tank should not have PlayerController")

# SCENARIO: Player tank has PlayerController child
func test_given_player_tank_when_created_then_has_player_controller():
	# Given/When: Player tank created with controller (in before_each)
	
	# Then: Player should have PlayerController as child
	var has_controller = false
	for child in player_tank.get_children():
		if child is PlayerController:
			has_controller = true
			break
	
	assert_true(has_controller, "Player tank should have PlayerController")

# SCENARIO: Enemy tank can still move programmatically
func test_given_enemy_tank_when_move_in_direction_called_then_moves():
	# Given: Enemy tank at position
	enemy_tank.global_position = Vector2(200, 200)
	var start_pos = enemy_tank.global_position
	
	# When: Programmatically move enemy
	enemy_tank.move_in_direction(Tank.Direction.LEFT)
	for i in range(5):
		enemy_tank._physics_process(0.016)
		await get_tree().physics_frame
	
	# Then: Enemy tank should have moved
	assert_ne(enemy_tank.global_position, start_pos, "Enemy should move programmatically")
	assert_lt(enemy_tank.global_position.x, start_pos.x, "Enemy should move left")
