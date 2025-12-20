extends GutTest

## Test suite for 3D lighting setup
## Tests DirectionalLight3D configuration for arcade-style lighting

const EXPECTED_ENERGY := 1.0
const EXPECTED_SHADOW_ENABLED := true

var lighting_scene: PackedScene
var lighting_instance: Node3D
var directional_light: DirectionalLight3D


func before_each():
	# Load the lighting scene before each test
	lighting_scene = load("res://scenes3d/game_lighting.tscn")
	if lighting_scene:
		lighting_instance = lighting_scene.instantiate()
		add_child_autofree(lighting_instance)
		# Find DirectionalLight3D in the scene tree
		directional_light = _find_directional_light(lighting_instance)


func _find_directional_light(node: Node) -> DirectionalLight3D:
	if node is DirectionalLight3D:
		return node
	for child in node.get_children():
		var result := _find_directional_light(child)
		if result:
			return result
	return null


func test_lighting_scene_loads():
	assert_not_null(lighting_scene, "Lighting scene should load successfully")


func test_lighting_instance_exists():
	assert_not_null(lighting_instance, "Lighting instance should exist")


func test_directional_light_exists():
	assert_not_null(directional_light, "DirectionalLight3D should exist in scene")


func test_light_energy_configured():
	assert_almost_eq(
		directional_light.light_energy,
		EXPECTED_ENERGY,
		0.1,
		"Light energy should be set to 1.0 for standard brightness"
	)


func test_shadow_enabled():
	assert_eq(
		directional_light.shadow_enabled,
		EXPECTED_SHADOW_ENABLED,
		"Shadows should be enabled for depth perception"
	)


func test_light_direction_configured():
	# Light should point downward and slightly angled for depth
	# Direction is controlled by rotation
	var rotation := directional_light.rotation_degrees
	
	# Light should be angled (not straight down)
	# Typical: rotation around X (pitch down) and possibly Y (side angle)
	assert_true(
		rotation.x != 0.0 or rotation.y != 0.0 or rotation.z != 0.0,
		"Light should have non-zero rotation for directional lighting"
	)


func test_light_affects_scene():
	# Light should be enabled and visible
	assert_true(directional_light.visible, "Light should be visible")


func test_light_color_is_white_or_warm():
	# Light color should be white (1,1,1) or warm for arcade feel
	var color := directional_light.light_color
	# Check it's not black or extremely dim
	assert_gt(color.r + color.g + color.b, 0.5, "Light should have sufficient color intensity")


func test_shadow_bias_configured():
	# Shadow bias should be set to reduce artifacts
	# Default or small positive value
	assert_true(
		directional_light.shadow_bias >= 0.0,
		"Shadow bias should be non-negative"
	)
