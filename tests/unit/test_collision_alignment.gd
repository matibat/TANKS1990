extends GutTest
## Tests collision shape alignment with visual elements

var main_scene: PackedScene
var test_instance: Node

func before_each():
	main_scene = load("res://scenes/main.tscn")
	test_instance = main_scene.instantiate()
	add_child_autofree(test_instance)

func test_wall_top_collision_matches_visual():
	# Given: WallTop static body with collision and visual
	var wall_top = test_instance.get_node("TestWalls/WallTop")
	var collision_shape = wall_top.get_node("CollisionShape2D")
	var color_rect = wall_top.get_node("ColorRect")
	
	# When: We check the sizes
	var shape_size = collision_shape.shape.size
	var visual_width = color_rect.size.x
	var visual_height = color_rect.size.y
	
	# Then: Collision shape matches visual (400x32)
	assert_eq(shape_size.x, 400.0, "WallTop collision width should be 400")
	assert_eq(shape_size.y, 32.0, "WallTop collision height should be 32")
	assert_eq(visual_width, 400.0, "WallTop visual width should be 400")
	assert_eq(visual_height, 32.0, "WallTop visual height should be 32")

func test_wall_left_collision_matches_visual():
	# Given: WallLeft static body with collision and visual
	var wall_left = test_instance.get_node("TestWalls/WallLeft")
	var collision_shape = wall_left.get_node("CollisionShape2D")
	var color_rect = wall_left.get_node("ColorRect")
	
	# When: We check the sizes
	var shape_size = collision_shape.shape.size
	var visual_width = color_rect.size.x
	var visual_height = color_rect.size.y
	
	# Then: Collision shape matches visual (32x400)
	assert_eq(shape_size.x, 32.0, "WallLeft collision width should be 32")
	assert_eq(shape_size.y, 400.0, "WallLeft collision height should be 400")
	assert_eq(visual_width, 32.0, "WallLeft visual width should be 32")
	assert_eq(visual_height, 400.0, "WallLeft visual height should be 400")

func test_wall_right_collision_matches_visual():
	# Given: WallRight static body with collision and visual
	var wall_right = test_instance.get_node("TestWalls/WallRight")
	var collision_shape = wall_right.get_node("CollisionShape2D")
	var color_rect = wall_right.get_node("ColorRect")
	
	# When: We check the sizes
	var shape_size = collision_shape.shape.size
	var visual_width = color_rect.size.x
	var visual_height = color_rect.size.y
	
	# Then: Collision shape matches visual (32x400)
	assert_eq(shape_size.x, 32.0, "WallRight collision width should be 32")
	assert_eq(shape_size.y, 400.0, "WallRight collision height should be 400")
	assert_eq(visual_width, 32.0, "WallRight visual width should be 32")
	assert_eq(visual_height, 400.0, "WallRight visual height should be 400")

func test_center_obstacle_collision_matches_visual():
	# Given: CenterObstacle static body with collision and visual
	var center_obstacle = test_instance.get_node("TestWalls/CenterObstacle")
	var collision_shape = center_obstacle.get_node("CollisionShape2D")
	var color_rect = center_obstacle.get_node("ColorRect")
	
	# When: We check the sizes
	var shape_size = collision_shape.shape.size
	var visual_width = color_rect.size.x
	var visual_height = color_rect.size.y
	
	# Then: Collision shape matches visual (64x64)
	assert_eq(shape_size.x, 64.0, "CenterObstacle collision width should be 64")
	assert_eq(shape_size.y, 64.0, "CenterObstacle collision height should be 64")
	assert_eq(visual_width, 64.0, "CenterObstacle visual width should be 64")
	assert_eq(visual_height, 64.0, "CenterObstacle visual height should be 64")

func test_collision_shapes_centered_on_visuals():
	# Given: All walls
	var walls = ["WallTop", "WallLeft", "WallRight", "CenterObstacle"]
	
	for wall_name in walls:
		# When: We check collision and visual positioning
		var wall = test_instance.get_node("TestWalls/" + wall_name)
		var collision_shape = wall.get_node("CollisionShape2D")
		var color_rect = wall.get_node("ColorRect")
		
		# Then: Collision shape should be at origin (0,0) relative to parent
		assert_eq(collision_shape.position, Vector2.ZERO, 
			"%s collision shape should be centered at origin" % wall_name)
		
		# And: Visual should be offset to center around collision
		var shape_size = collision_shape.shape.size
		var expected_offset = Vector2(-shape_size.x / 2, -shape_size.y / 2)
		assert_almost_eq(color_rect.position.x, expected_offset.x, 0.1,
			"%s visual X position should match collision center" % wall_name)
		assert_almost_eq(color_rect.position.y, expected_offset.y, 0.1,
			"%s visual Y position should match collision center" % wall_name)

func test_walls_on_correct_collision_layer():
	# Given: All walls
	var walls = ["WallTop", "WallLeft", "WallRight", "CenterObstacle"]
	
	for wall_name in walls:
		# When: We check the collision layer
		var wall = test_instance.get_node("TestWalls/" + wall_name)
		
		# Then: Should be on layer 2 (terrain)
		assert_eq(wall.collision_layer, 2, 
			"%s should be on collision layer 2 (terrain)" % wall_name)
		assert_eq(wall.collision_mask, 0,
			"%s should not detect any collisions (mask = 0)" % wall_name)
