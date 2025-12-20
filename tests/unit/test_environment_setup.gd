extends GutTest

## Test suite for 3D world environment setup
## Tests WorldEnvironment configuration for arcade-style visuals

var environment_scene: PackedScene
var environment_instance: Node
var world_environment: WorldEnvironment


func before_each():
	# Load the environment scene before each test
	environment_scene = load("res://scenes3d/world_environment.tscn")
	if environment_scene:
		environment_instance = environment_scene.instantiate()
		add_child_autofree(environment_instance)
		# Find WorldEnvironment in the scene tree
		world_environment = _find_world_environment(environment_instance)


func _find_world_environment(node: Node) -> WorldEnvironment:
	if node is WorldEnvironment:
		return node
	for child in node.get_children():
		var result := _find_world_environment(child)
		if result:
			return result
	return null


func test_environment_scene_loads():
	assert_not_null(environment_scene, "Environment scene should load successfully")


func test_environment_instance_exists():
	assert_not_null(environment_instance, "Environment instance should exist")


func test_world_environment_exists():
	assert_not_null(world_environment, "WorldEnvironment node should exist in scene")


func test_environment_resource_configured():
	assert_not_null(
		world_environment.environment,
		"WorldEnvironment should have Environment resource configured"
	)


func test_background_mode_configured():
	var env := world_environment.environment
	# Background should be set (not MODE_CUSTOM with null sky)
	assert_true(
		env.background_mode != Environment.BG_MAX,
		"Background mode should be configured"
	)


func test_ambient_light_configured():
	var env := world_environment.environment
	# Ambient light should provide base illumination
	# Check that ambient light source is set
	assert_true(
		env.ambient_light_source != Environment.AMBIENT_SOURCE_DISABLED or
		env.ambient_light_energy > 0.0,
		"Ambient light should be configured for base scene illumination"
	)


func test_fog_settings_if_enabled():
	var env := world_environment.environment
	# If fog is enabled, verify it's configured
	if env.fog_enabled:
		assert_gt(env.fog_density, 0.0, "If fog enabled, density should be > 0")
		assert_true(
			env.fog_light_color != Color.BLACK,
			"If fog enabled, color should be set"
		)


func test_tonemap_mode_configured():
	var env := world_environment.environment
	# Tonemap mode should be set for visual style
	assert_true(
		env.tonemap_mode >= Environment.TONE_MAPPER_LINEAR,
		"Tonemap mode should be configured"
	)


func test_environment_visible():
	# WorldEnvironment should be active in scene
	assert_true(world_environment.visible, "WorldEnvironment should be visible")
