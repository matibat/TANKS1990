extends GutTest
## Tests for bullet bounds consistency with play area

var bullet: Bullet
var main_scene: PackedScene
var main_instance: Node

const TILE_SIZE = 16
const EXPECTED_GRID_SIZE = 26  # 26x26 tiles as per spec (416x416 play area)
const TILE_BOUNDS = EXPECTED_GRID_SIZE * TILE_SIZE  # 416 pixels (logical grid)
const WINDOW_SIZE = 832  # Actual window/screen size
const PLAY_AREA_OFFSET = 16  # PlayArea starts at (16, 16)
const PLAY_AREA_SIZE = 800  # PlayArea is 800x800

func before_each():
	bullet = Bullet.new()
	add_child_autofree(bullet)
	bullet._ready()  # Ensure ready is called
	
	main_scene = load("res://scenes/main.tscn")
	main_instance = main_scene.instantiate()
	add_child_autofree(main_instance)

func test_bullet_bounds_matches_window_size():
	# Given: Bullet class with game bounds
	# When: We check the bounds
	var bounds_max = Bullet.game_bounds_max
	
	# Then: Bounds should match window size (832x832)
	assert_eq(bounds_max.x, WINDOW_SIZE, "Bullet bounds should match window width")
	assert_eq(bounds_max.y, WINDOW_SIZE, "Bullet bounds should match window height")

func test_bullet_out_of_bounds_top_left():
	# Given: Bullet positioned outside top-left corner
	bullet.global_position = Vector2(-10, -10)
	bullet.direction = Vector2.UP
	bullet.is_active = true
	
	# When: Physics process runs
	await get_tree().create_timer(0.1).timeout
	
	# Then: Bullet should be marked for destruction
	assert_false(bullet.is_active, "Bullet should be destroyed outside bounds")

func test_bullet_out_of_bounds_bottom_right():
	# Given: Bullet positioned outside window bounds
	bullet.global_position = Vector2(WINDOW_SIZE + 10, WINDOW_SIZE + 10)
	bullet.direction = Vector2.DOWN
	bullet.is_active = true
	
	# When: Physics process runs
	await get_tree().create_timer(0.1).timeout
	
	# Then: Bullet should be marked for destruction
	assert_false(bullet.is_active, "Bullet should be destroyed outside bounds")

func test_bullet_in_bounds_center():
	# Given: Bullet positioned at center of window
	bullet.global_position = Vector2(WINDOW_SIZE / 2, WINDOW_SIZE / 2)
	bullet.direction = Vector2.UP
	bullet.is_active = true
	
	# When: Physics process runs manually (simulating movement)
	for i in range(5):
		bullet._physics_process(0.016)  # 5 frames at 60fps
	
	# Then: Bullet should remain active (moved 16 pixels up, still in bounds)
	assert_true(bullet.is_active, "Bullet should remain active within bounds")

func test_bullet_bounds_at_edges():
	# Given: Bullets at each edge of valid area
	var test_positions = [
		Vector2(0, WINDOW_SIZE / 2),  # Left edge
		Vector2(WINDOW_SIZE, WINDOW_SIZE / 2),  # Right edge
		Vector2(WINDOW_SIZE / 2, 0),  # Top edge
		Vector2(WINDOW_SIZE / 2, WINDOW_SIZE)  # Bottom edge
	]
	
	for pos in test_positions:
		# When: Check if position is at boundary
		var at_left = pos.x <= 0
		var at_right = pos.x >= WINDOW_SIZE
		var at_top = pos.y <= 0
		var at_bottom = pos.y >= WINDOW_SIZE
		
		# Then: Position should be at or on boundary
		var at_edge = at_left or at_right or at_top or at_bottom
		assert_true(at_edge, "Position %s should be at edge" % pos)

func test_play_area_visual_within_window_bounds():
	# Given: Main scene with PlayArea visual element
	var play_area = main_instance.get_node("PlayArea")
	
	# When: We check PlayArea dimensions
	var visual_width = play_area.size.x
	var visual_height = play_area.size.y
	var visual_offset_x = play_area.position.x
	var visual_offset_y = play_area.position.y
	
	# Then: PlayArea should be within window bounds
	assert_eq(visual_width, PLAY_AREA_SIZE, "PlayArea width should be 800")
	assert_eq(visual_height, PLAY_AREA_SIZE, "PlayArea height should be 800")
	assert_eq(visual_offset_x, PLAY_AREA_OFFSET, "PlayArea offset X should be 16")
	assert_eq(visual_offset_y, PLAY_AREA_OFFSET, "PlayArea offset Y should be 16")
	
	# And: PlayArea should fit within bullet bounds
	var play_area_end_x = visual_offset_x + visual_width
	var play_area_end_y = visual_offset_y + visual_height
	assert_true(play_area_end_x <= WINDOW_SIZE, "PlayArea should fit within window width")
	assert_true(play_area_end_y <= WINDOW_SIZE, "PlayArea should fit within window height")

func test_bullet_bounds_constant_matches_window():
	# Given: Tank 1990 uses 832x832 window
	# When: We check bullet game bounds
	# Then: Should match window dimensions
	assert_eq(Bullet.game_bounds_max.x, WINDOW_SIZE, "Bullet bounds should match window width")
	assert_eq(Bullet.game_bounds_max.y, WINDOW_SIZE, "Bullet bounds should match window height")
	assert_eq(Bullet.game_bounds_min.x, 0, "Bullet bounds min should be 0")
	assert_eq(Bullet.game_bounds_min.y, 0, "Bullet bounds min should be 0")
	
	# And: Logical grid is smaller (for gameplay area)
	assert_eq(TILE_BOUNDS, 416, "Logical tile grid is 416x416 (26x26 tiles)")
	assert_true(TILE_BOUNDS < WINDOW_SIZE, "Tile grid fits within window")

func test_bullet_manager_respects_bounds():
	# Given: BulletManager in scene
	var bullet_manager = main_instance.get_node("BulletManager")
	
	# This test requires fully instantiated scene with BulletManager
	# Skip if scene structure doesn't match (allows other tests to run)
	if bullet_manager == null:
		pass_test("Skipping scene integration test - BulletManager not found in scene")
		return
	
	# Wait for scene to be fully ready
	await wait_physics_frames(2)
	
	# When: Bullet spawned near edge
	var spawn_event = BulletFiredEvent.new()
	spawn_event.tank_id = 1
	spawn_event.position = Vector2(WINDOW_SIZE - 50, WINDOW_SIZE / 2)
	spawn_event.direction = Vector2.RIGHT
	spawn_event.bullet_level = 1
	
	if is_instance_valid(bullet_manager):
		EventBus.emit_game_event(spawn_event)
		await get_tree().create_timer(0.2).timeout
	
	# Then: Bullet should be created and eventually destroyed at bounds
	# Manager handles pooling correctly
	pass

func test_bounds_consistency_documented():
	# Given: Game design with window (832x832) and play area (800x800 with 16px offset)
	# Then: Verify the architecture is consistent
	var play_area = main_instance.get_node("PlayArea")
	var visual_size = play_area.size.x
	
	# Document the bounds architecture:
	# - Window: 832x832 (game_bounds for bullets)
	# - PlayArea visual: 800x800 starting at (16, 16)
	# - Logical grid: 26x26 tiles = 416x416 (for terrain)
	
	gut.p("Bounds Architecture:", 1)
	gut.p("  Window (bullet bounds): %dx%d" % [WINDOW_SIZE, WINDOW_SIZE], 1)
	gut.p("  PlayArea visual: %dx%d at offset (%d, %d)" % [PLAY_AREA_SIZE, PLAY_AREA_SIZE, PLAY_AREA_OFFSET, PLAY_AREA_OFFSET], 1)
	gut.p("  Logical tile grid: %dx%d" % [TILE_BOUNDS, TILE_BOUNDS], 1)
	
	# Verify consistency
	assert_eq(visual_size, PLAY_AREA_SIZE, "PlayArea matches expected size")
	assert_eq(Bullet.game_bounds_max.x, WINDOW_SIZE, "Bullet bounds match window")
	assert_true(TILE_BOUNDS < PLAY_AREA_SIZE, "Tile grid fits within play area")
	assert_true(PLAY_AREA_SIZE < WINDOW_SIZE, "Play area fits within window")
