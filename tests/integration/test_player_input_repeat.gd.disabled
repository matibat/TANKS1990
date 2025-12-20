extends GutTest
## Integration test for player input repeat movement on hold

var player_tank: Tank
var player_controller: PlayerController
var test_scene: Node2D

func before_each() -> void:
	# Create test scene
	test_scene = Node2D.new()
	add_child_autofree(test_scene)
	
	# Create player tank
	player_tank = Tank.new()
	player_tank.tank_type = Tank.TankType.PLAYER
	player_tank.position = Vector2(200, 200)  # Center-ish position, not at edge
	player_tank.current_state = Tank.State.IDLE
	player_tank.spawn_timer = 0.0
	test_scene.add_child(player_tank)
	player_tank.add_to_group("tanks")
	
	# Create player controller
	player_controller = PlayerController.new()
	player_controller.tank = player_tank
	player_controller.player_id = 0
	test_scene.add_child(player_controller)

func after_each() -> void:
	player_tank = null
	player_controller = null
	test_scene = null

func test_given_player_holds_move_right_when_time_passes_then_moves_multiple_steps() -> void:
	# Given: Player tank at position (200, 200) - gets snapped to (208, 208) on grid
	var initial_position = player_tank.position
	assert_eq(initial_position, Vector2(208, 208), "Tank starts at expected position")
	
	# When: Simulate holding right arrow for 2 seconds (should move multiple times)
	Input.action_press("move_right")
	
	# Simulate physics processing for 2 seconds (120 frames at 60fps)
	var delta = 1.0 / 60.0  # 60fps
	for i in range(120):  # 2 seconds
		player_controller._physics_process(delta)
		await wait_physics_frames(1)
	
	# Then: Tank should have moved right multiple times (at least 2-3 steps)
	var final_position = player_tank.position
	var distance_moved = final_position.x - initial_position.x
	assert_gt(distance_moved, 16.0, "Tank should have moved right at least one tile")
	# With repeat delay, should move multiple times in 2 seconds
	assert_gt(distance_moved, 32.0, "Tank should have moved multiple tiles while holding")
	
	# Cleanup
	Input.action_release("move_right")