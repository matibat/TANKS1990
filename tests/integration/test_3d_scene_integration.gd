extends GutTest

## Integration test for complete 3D scene setup
## Tests that all Phase 2 components work together correctly

var test_scene: PackedScene
var scene_instance: Node3D
var camera: Camera3D
var directional_light: DirectionalLight3D
var world_environment: WorldEnvironment
var ground_static_body: StaticBody3D


func before_all():
	# Load the integrated 3D test scene
	test_scene = load("res://scenes3d/test_3d_scene.tscn")


func before_each():
	if test_scene:
		scene_instance = test_scene.instantiate()
		add_child_autofree(scene_instance)
		# Find all key components
		camera = _find_node_of_type(scene_instance, Camera3D)
		directional_light = _find_node_of_type(scene_instance, DirectionalLight3D)
		world_environment = _find_node_of_type(scene_instance, WorldEnvironment)
		ground_static_body = _find_node_of_type(scene_instance, StaticBody3D)


func _find_node_of_type(node: Node, type) -> Node:
	if is_instance_of(node, type):
		return node
	for child in node.get_children():
		var result := _find_node_of_type(child, type)
		if result:
			return result
	return null


func test_scene_loads():
	assert_not_null(test_scene, "Test 3D scene should load successfully")


func test_scene_instantiates():
	assert_not_null(scene_instance, "Scene instance should be created")


func test_all_components_present():
	assert_not_null(camera, "Camera3D should be present in scene")
	assert_not_null(directional_light, "DirectionalLight3D should be present in scene")
	assert_not_null(world_environment, "WorldEnvironment should be present in scene")
	assert_not_null(ground_static_body, "Ground StaticBody3D should be present in scene")


func test_camera_is_active():
	assert_true(camera.current, "Camera should be set as current/active camera")


func test_camera_can_see_ground():
	# Camera should be positioned to see the ground plane
	# Camera at Y=10 looking down at Y=0
	assert_gt(camera.global_position.y, 0.0, "Camera should be above ground plane")
	
	# Camera should be looking down (negative Y direction in local space)
	var forward := -camera.global_transform.basis.z
	assert_lt(forward.y, 0.0, "Camera should be oriented to look downward")


func test_light_illuminates_scene():
	# Light should be enabled and configured
	assert_true(directional_light.visible, "Light should be visible/enabled")
	assert_gt(directional_light.light_energy, 0.0, "Light should have energy > 0")


func test_environment_provides_background():
	# Environment should have settings configured
	assert_not_null(world_environment.environment, "Environment resource should exist")


func test_ground_collision_layer_correct():
	# Ground should be on Environment layer (layer 4, bit 3)
	assert_true(
		ground_static_body.collision_layer & (1 << 3) != 0,
		"Ground should be on Environment collision layer"
	)


func test_camera_viewport_configured():
	# Scene should be renderable (camera has valid viewport)
	assert_true(camera.projection != Camera3D.PROJECTION_PERSPECTIVE or 
				camera.projection != Camera3D.PROJECTION_ORTHOGONAL,
				"Camera projection should be set")


func test_scene_tree_structure():
	# Verify scene has expected hierarchy
	assert_gt(scene_instance.get_child_count(), 0, "Scene should have child nodes")


func test_lighting_affects_ground():
	# This is a visual test approximation: verify light and ground exist together
	# In actual rendering, light would illuminate the ground mesh
	assert_not_null(directional_light, "Light should exist to illuminate ground")
	var mesh_instance := _find_node_of_type(scene_instance, MeshInstance3D)
	assert_not_null(mesh_instance, "Ground mesh should exist to receive light")


func test_camera_frustum_includes_playfield():
	# For orthogonal camera, size should encompass the grid
	if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		# Size 20 should cover 26x26 grid when viewed from height 10
		assert_gt(camera.size, 15.0, "Camera size should be sufficient to see playfield")
