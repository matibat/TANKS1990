extends GutTest

## Phase 2: Test 3D Camera and Environment Setup
## Tests orthogonal camera, lighting, and ground reference for top-down view

var test_scene: Node3D
var camera: Camera3D
var light: DirectionalLight3D
var ground: MeshInstance3D
var world_env: WorldEnvironment

const GRID_SIZE = 26  # 26x26 grid from specs
const GRID_CENTER_X = 13.0  # Center of 26 units
const GRID_CENTER_Z = 13.0
const CAMERA_HEIGHT = 10.0
const EPSILON = 0.001

func before_each():
	# Load the 3D environment test scene
	var scene_path = "res://scenes3d/test_3d_environment.tscn"
	if ResourceLoader.exists(scene_path):
		test_scene = load(scene_path).instantiate()
		add_child(test_scene)
		
		# Get references to scene nodes
		camera = test_scene.get_node_or_null("Camera3D")
		light = test_scene.get_node_or_null("DirectionalLight3D")
		ground = test_scene.get_node_or_null("GroundPlane")
		world_env = test_scene.get_node_or_null("WorldEnvironment")
	else:
		# Create minimal test scene if file doesn't exist yet
		test_scene = Node3D.new()
		add_child(test_scene)

func after_each():
	if test_scene:
		test_scene.queue_free()
		test_scene = null

func test_camera_exists():
	assert_not_null(camera, "Camera3D should exist in scene")

func test_camera_orthogonal_projection():
	assert_not_null(camera, "Camera3D should exist")
	assert_eq(
		camera.projection, 
		Camera3D.PROJECTION_ORTHOGONAL,
		"Camera should use orthogonal projection for top-down arcade view"
	)

func test_camera_position_centered():
	assert_not_null(camera, "Camera3D should exist")
	var pos = camera.global_position
	
	# Camera should be centered over 26x26 grid at height 10
	assert_almost_eq(pos.x, GRID_CENTER_X, EPSILON, "Camera X should be at grid center")
	assert_almost_eq(pos.y, CAMERA_HEIGHT, EPSILON, "Camera Y should be at height 10")
	assert_almost_eq(pos.z, GRID_CENTER_Z, EPSILON, "Camera Z should be at grid center")

func test_camera_rotation_top_down():
	assert_not_null(camera, "Camera3D should exist")
	
	# Top-down view: -90 degrees on X axis (looking down Y-axis)
	var rotation_deg = camera.rotation_degrees
	assert_almost_eq(rotation_deg.x, -90.0, 1.0, "Camera should look straight down (X=-90°)")
	assert_almost_eq(rotation_deg.y, 0.0, 1.0, "Camera Y rotation should be 0°")
	assert_almost_eq(rotation_deg.z, 0.0, 1.0, "Camera Z rotation should be 0°")

func test_camera_orthogonal_size():
	assert_not_null(camera, "Camera3D should exist")
	assert_gt(camera.size, 15.0, "Orthogonal size should be adequate for 26x26 grid visibility")
	assert_lt(camera.size, 30.0, "Orthogonal size should not be excessively large")

func test_camera_near_far_planes():
	assert_not_null(camera, "Camera3D should exist")
	assert_gt(camera.near, 0.0, "Near plane should be positive")
	assert_lt(camera.near, 1.0, "Near plane should be close for top-down")
	assert_gt(camera.far, 50.0, "Far plane should cover game depth")

func test_directional_light_exists():
	assert_not_null(light, "DirectionalLight3D should exist for scene lighting")

func test_directional_light_energy():
	assert_not_null(light, "DirectionalLight3D should exist")
	assert_almost_eq(light.light_energy, 1.0, 0.1, "Light energy should be ~1.0")

func test_directional_light_shadows():
	assert_not_null(light, "DirectionalLight3D should exist")
	assert_true(light.shadow_enabled, "Shadows should be enabled for depth perception")

func test_directional_light_direction():
	assert_not_null(light, "DirectionalLight3D should exist")
	
	# Light should point downward and at an angle for shading
	# Direction vector should have negative Y component
	var direction = -light.global_transform.basis.z  # Light points along -Z in local space
	assert_lt(direction.y, 0.0, "Light should point downward (negative Y)")

func test_ground_plane_exists():
	assert_not_null(ground, "Ground plane should exist as visual reference")

func test_ground_plane_at_zero_height():
	assert_not_null(ground, "Ground plane should exist")
	var pos = ground.global_position
	assert_almost_eq(pos.y, 0.0, EPSILON, "Ground should be at Y=0")

func test_ground_plane_has_mesh():
	assert_not_null(ground, "Ground plane should exist")
	assert_not_null(ground.mesh, "Ground plane should have a mesh assigned")

func test_world_environment_exists():
	# WorldEnvironment is optional but recommended
	if world_env != null:
		assert_not_null(world_env.environment, "WorldEnvironment should have Environment resource")

func test_coordinate_system_y_up():
	# Verify 3D coordinate system: Y-up (different from 2D Y-down)
	# This is implicit in Godot 3D, but we document it
	assert_not_null(camera, "Camera should exist for coordinate system test")
	
	# Camera at positive Y looks down = Y-up system
	assert_gt(camera.global_position.y, 0.0, "Positive Y means 'up' in 3D coordinate system")

func test_scene_hierarchy():
	assert_not_null(test_scene, "Test scene should exist")
	
	# Verify essential nodes are children of test_scene
	var children_names = []
	for child in test_scene.get_children():
		children_names.append(child.name)
	
	assert_true(
		"Camera3D" in children_names or camera != null,
		"Scene should contain Camera3D node"
	)
	assert_true(
		"DirectionalLight3D" in children_names or light != null,
		"Scene should contain DirectionalLight3D node"
	)

# Helper function for approximate equality
func assert_almost_eq(actual: float, expected: float, delta: float, text: String = ""):
	var diff = abs(actual - expected)
	assert_true(
		diff <= delta,
		"%s: expected %s ± %s, got %s (diff: %s)" % [text, expected, delta, actual, diff]
	)
