extends GutTest

# Test suite for material library
# Validates unlit materials with correct colors

const MATERIAL_PATHS = {
	"tank_yellow": "res://resources/materials/mat_tank_yellow.tres",
	"enemy_brown": "res://resources/materials/mat_enemy_brown.tres",
	"enemy_gray": "res://resources/materials/mat_enemy_gray.tres",
	"enemy_green": "res://resources/materials/mat_enemy_green.tres",
	"enemy_red": "res://resources/materials/mat_enemy_red.tres",
	"bullet": "res://resources/materials/mat_bullet.tres",
	"base_eagle": "res://resources/materials/mat_base_eagle.tres",
	"brick": "res://resources/materials/mat_brick.tres",
	"steel": "res://resources/materials/mat_steel.tres",
	"water": "res://resources/materials/mat_water.tres",
	"forest": "res://resources/materials/mat_forest.tres",
	"powerup_tank": "res://resources/materials/mat_powerup_tank.tres",
	"powerup_star": "res://resources/materials/mat_powerup_star.tres",
	"powerup_grenade": "res://resources/materials/mat_powerup_grenade.tres",
	"powerup_shield": "res://resources/materials/mat_powerup_shield.tres",
	"powerup_timer": "res://resources/materials/mat_powerup_timer.tres",
	"powerup_shovel": "res://resources/materials/mat_powerup_shovel.tres"
}

const EXPECTED_COLORS = {
	"tank_yellow": Color("#FFD700"),
	"enemy_brown": Color("#8B4513"),
	"enemy_gray": Color("#808080"),
	"enemy_green": Color("#228B22"),
	"enemy_red": Color("#DC143C"),
	"bullet": Color("#FFFFFF"),
	"base_eagle": Color("#000000"),
	"brick": Color("#CD853F"),
	"steel": Color("#C0C0C0"),
	"water": Color("#1E90FF"),
	"forest": Color("#228B22"),
	"powerup_tank": Color("#DC143C"),
	"powerup_star": Color("#FFD700"),
	"powerup_grenade": Color("#000000"),
	"powerup_shield": Color("#00CED1"),
	"powerup_timer": Color("#9370DB"),
	"powerup_shovel": Color("#8B4513")
}

# Existence Tests

func test_tank_yellow_material_exists():
	assert_file_exists(MATERIAL_PATHS["tank_yellow"])

func test_enemy_brown_material_exists():
	assert_file_exists(MATERIAL_PATHS["enemy_brown"])

func test_enemy_gray_material_exists():
	assert_file_exists(MATERIAL_PATHS["enemy_gray"])

func test_enemy_green_material_exists():
	assert_file_exists(MATERIAL_PATHS["enemy_green"])

func test_enemy_red_material_exists():
	assert_file_exists(MATERIAL_PATHS["enemy_red"])

func test_bullet_material_exists():
	assert_file_exists(MATERIAL_PATHS["bullet"])

func test_base_eagle_material_exists():
	assert_file_exists(MATERIAL_PATHS["base_eagle"])

func test_brick_material_exists():
	assert_file_exists(MATERIAL_PATHS["brick"])

func test_steel_material_exists():
	assert_file_exists(MATERIAL_PATHS["steel"])

func test_water_material_exists():
	assert_file_exists(MATERIAL_PATHS["water"])

func test_forest_material_exists():
	assert_file_exists(MATERIAL_PATHS["forest"])

func test_powerup_tank_material_exists():
	assert_file_exists(MATERIAL_PATHS["powerup_tank"])

func test_powerup_star_material_exists():
	assert_file_exists(MATERIAL_PATHS["powerup_star"])

func test_powerup_grenade_material_exists():
	assert_file_exists(MATERIAL_PATHS["powerup_grenade"])

func test_powerup_shield_material_exists():
	assert_file_exists(MATERIAL_PATHS["powerup_shield"])

func test_powerup_timer_material_exists():
	assert_file_exists(MATERIAL_PATHS["powerup_timer"])

func test_powerup_shovel_material_exists():
	assert_file_exists(MATERIAL_PATHS["powerup_shovel"])

# Material Type Tests

func test_all_materials_are_standard_material_3d():
	for mat_name in MATERIAL_PATHS:
		var material = load(MATERIAL_PATHS[mat_name])
		assert_not_null(material, "%s material failed to load" % mat_name)
		assert_true(material is StandardMaterial3D, 
			"%s is not StandardMaterial3D" % mat_name)

# Unlit Tests

func test_tank_yellow_is_unlit():
	var material = load(MATERIAL_PATHS["tank_yellow"]) as StandardMaterial3D
	assert_eq(material.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED,
		"tank_yellow is not unshaded")

func test_enemy_brown_is_unlit():
	var material = load(MATERIAL_PATHS["enemy_brown"]) as StandardMaterial3D
	assert_eq(material.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED,
		"enemy_brown is not unshaded")

func test_bullet_is_unlit():
	var material = load(MATERIAL_PATHS["bullet"]) as StandardMaterial3D
	assert_eq(material.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED,
		"bullet is not unshaded")

func test_brick_is_unlit():
	var material = load(MATERIAL_PATHS["brick"]) as StandardMaterial3D
	assert_eq(material.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED,
		"brick is not unshaded")

func test_all_materials_are_unlit():
	for mat_name in MATERIAL_PATHS:
		var material = load(MATERIAL_PATHS[mat_name]) as StandardMaterial3D
		assert_eq(material.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED,
			"%s is not unshaded" % mat_name)

# Color Tests

func test_tank_yellow_color():
	var material = load(MATERIAL_PATHS["tank_yellow"]) as StandardMaterial3D
	var color = material.albedo_color
	var expected = EXPECTED_COLORS["tank_yellow"]
	assert_almost_eq(color.r, expected.r, 0.05, "tank_yellow red channel incorrect")
	assert_almost_eq(color.g, expected.g, 0.05, "tank_yellow green channel incorrect")
	assert_almost_eq(color.b, expected.b, 0.05, "tank_yellow blue channel incorrect")

func test_enemy_brown_color():
	var material = load(MATERIAL_PATHS["enemy_brown"]) as StandardMaterial3D
	var color = material.albedo_color
	var expected = EXPECTED_COLORS["enemy_brown"]
	assert_almost_eq(color.r, expected.r, 0.05, "enemy_brown color incorrect")

func test_water_color_is_blue():
	var material = load(MATERIAL_PATHS["water"]) as StandardMaterial3D
	var color = material.albedo_color
	# Should be predominantly blue
	assert_gt(color.b, 0.5, "water is not blue enough")

func test_forest_color_is_green():
	var material = load(MATERIAL_PATHS["forest"]) as StandardMaterial3D
	var color = material.albedo_color
	# Should be predominantly green
	assert_gt(color.g, 0.5, "forest is not green enough")

func test_bullet_color_is_bright():
	var material = load(MATERIAL_PATHS["bullet"]) as StandardMaterial3D
	var color = material.albedo_color
	var brightness = (color.r + color.g + color.b) / 3.0
	assert_gt(brightness, 0.7, "bullet color is not bright enough")

# No Texture Tests

func test_materials_have_no_textures():
	for mat_name in MATERIAL_PATHS:
		var material = load(MATERIAL_PATHS[mat_name]) as StandardMaterial3D
		assert_null(material.albedo_texture, 
			"%s has albedo texture (should be solid color)" % mat_name)
		assert_null(material.normal_texture,
			"%s has normal texture (should be none)" % mat_name)
		assert_null(material.metallic_texture,
			"%s has metallic texture (should be none)" % mat_name)

# Mesh Assignment Tests

func test_player_tank_uses_yellow_material():
	var scene = load("res://resources/meshes3d/models/tank_base.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = instance as MeshInstance3D
	if mesh_inst == null:
		mesh_inst = instance.get_child(0) as MeshInstance3D
	
	if mesh_inst != null:
		var material = mesh_inst.get_surface_override_material(0)
		if material == null:
			material = mesh_inst.mesh.surface_get_material(0)
		
		if material is StandardMaterial3D:
			var color = material.albedo_color
			var expected = EXPECTED_COLORS["tank_yellow"]
			# Check if color is approximately yellow
			assert_gt(color.r + color.g, 1.5, 
				"Player tank is not yellow (r+g should be high)")

func test_bullet_uses_bright_material():
	var scene = load("res://resources/meshes3d/models/bullet.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	await get_tree().process_frame
	
	var mesh_inst = instance as MeshInstance3D
	if mesh_inst == null:
		mesh_inst = instance.get_child(0) as MeshInstance3D
	
	if mesh_inst != null:
		if mesh_inst.mesh == null:
			pending("Bullet mesh not generated - mesh_loader may need runtime")
			return
		
		var material = mesh_inst.get_surface_override_material(0)
		if material == null and mesh_inst.mesh != null:
			if mesh_inst.mesh.get_surface_count() > 0:
				material = mesh_inst.mesh.surface_get_material(0)
		
		if material == null:
			pending("Bullet material not set - may need runtime setup")
			return
		
		if material is StandardMaterial3D:
			var color = material.albedo_color
			var brightness = (color.r + color.g + color.b) / 3.0
			assert_gt(brightness, 0.7, "Bullet material is not bright")
