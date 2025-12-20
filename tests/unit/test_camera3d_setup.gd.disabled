extends GutTest

## Test suite for 3D camera setup and configuration
## Tests orthogonal projection, positioning, and playfield visibility

const GRID_SIZE := 26
const EXPECTED_CAMERA_HEIGHT := 10.0
const EXPECTED_ORTHO_SIZE := 20.0

var camera_scene: PackedScene
var camera_instance: Camera3D


func before_each():
	# Load the camera scene before each test
	camera_scene = load("res://scenes3d/camera_3d.tscn")
	if camera_scene:
		camera_instance = camera_scene.instantiate()
		add_child_autofree(camera_instance)


func test_camera_scene_loads():
	assert_not_null(camera_scene, "Camera scene should load successfully")


func test_camera_node_exists():
	assert_not_null(camera_instance, "Camera3D instance should exist")
	assert_true(camera_instance is Camera3D, "Instance should be Camera3D type")


func test_camera_uses_orthogonal_projection():
	assert_eq(
		camera_instance.projection,
		Camera3D.PROJECTION_ORTHOGONAL,
		"Camera should use orthogonal projection for top-down view"
	)


func test_camera_position_centered_over_grid():
	# Camera should be centered over 26x26 grid at height Y=10
	var expected_x := GRID_SIZE / 2.0
	var expected_z := GRID_SIZE / 2.0
	var pos := camera_instance.position
	
	assert_almost_eq(pos.x, expected_x, 0.1, "Camera X should be centered at grid midpoint")
	assert_almost_eq(pos.y, EXPECTED_CAMERA_HEIGHT, 0.1, "Camera Y should be at height 10")
	assert_almost_eq(pos.z, expected_z, 0.1, "Camera Z should be centered at grid midpoint")


func test_camera_rotation_top_down():
	# Camera should look straight down (-90° on X-axis)
	var rotation_deg := camera_instance.rotation_degrees
	
	assert_almost_eq(rotation_deg.x, -90.0, 1.0, "Camera should rotate -90° on X for top-down view")
	assert_almost_eq(rotation_deg.y, 0.0, 1.0, "Camera Y rotation should be 0")
	assert_almost_eq(rotation_deg.z, 0.0, 1.0, "Camera Z rotation should be 0")


func test_camera_orthogonal_size_configured():
	# Size should provide full playfield visibility
	assert_almost_eq(
		camera_instance.size,
		EXPECTED_ORTHO_SIZE,
		0.5,
		"Orthogonal size should be configured for full playfield view"
	)


func test_camera_is_current():
	# Camera should be marked as current/active
	assert_true(camera_instance.current, "Camera should be set as current camera")


func test_camera_far_plane_sufficient():
	# Far plane should be > camera height to render ground
	assert_gt(camera_instance.far, EXPECTED_CAMERA_HEIGHT, "Far plane should exceed camera height")


func test_camera_near_plane_reasonable():
	# Near plane should be small but not zero
	assert_gt(camera_instance.near, 0.0, "Near plane should be > 0")
	assert_lt(camera_instance.near, 1.0, "Near plane should be < 1 for close objects")
