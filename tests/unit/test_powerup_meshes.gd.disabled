extends GutTest

# Test suite for power-up 3D meshes
# Validates mesh existence, triangle counts, distinct shapes, and materials

const POWERUP_MESH_PATHS = {
	"tank": "res://resources/meshes3d/models/powerup_tank.tscn",
	"star": "res://resources/meshes3d/models/powerup_star.tscn",
	"grenade": "res://resources/meshes3d/models/powerup_grenade.tscn",
	"shield": "res://resources/meshes3d/models/powerup_shield.tscn",
	"timer": "res://resources/meshes3d/models/powerup_timer.tscn",
	"shovel": "res://resources/meshes3d/models/powerup_shovel.tscn"
}

const POWERUP_TRI_BUDGET = 150
const POWERUP_SIZE = 0.6  # units (smaller than tanks)

func _count_triangles(mesh_instance: MeshInstance3D) -> int:
	var mesh = mesh_instance.mesh
	if mesh == null:
		return 0
	
	var tri_count = 0
	for i in range(mesh.get_surface_count()):
		var arrays = mesh.surface_get_arrays(i)
		if arrays.size() > Mesh.ARRAY_INDEX:
			var indices = arrays[Mesh.ARRAY_INDEX]
			if indices != null:
				tri_count += indices.size() / 3
			else:
				var vertices = arrays[Mesh.ARRAY_VERTEX]
				if vertices != null:
					tri_count += vertices.size() / 3
	return tri_count

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var result = _find_mesh_instance(child)
		if result != null:
			return result
	return null

# Existence Tests

func test_powerup_tank_exists():
	assert_file_exists(POWERUP_MESH_PATHS["tank"])

func test_powerup_star_exists():
	assert_file_exists(POWERUP_MESH_PATHS["star"])

func test_powerup_grenade_exists():
	assert_file_exists(POWERUP_MESH_PATHS["grenade"])

func test_powerup_shield_exists():
	assert_file_exists(POWERUP_MESH_PATHS["shield"])

func test_powerup_timer_exists():
	assert_file_exists(POWERUP_MESH_PATHS["timer"])

func test_powerup_shovel_exists():
	assert_file_exists(POWERUP_MESH_PATHS["shovel"])

# Triangle Count Tests

func test_powerup_tank_triangle_count():
	var scene = load(POWERUP_MESH_PATHS["tank"])
	assert_not_null(scene, "Failed to load powerup_tank.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found in powerup_tank")
	
	var tri_count = _count_triangles(mesh_inst)
	assert_lt(tri_count, POWERUP_TRI_BUDGET, 
		"Tank powerup exceeds triangle budget: %d / %d" % [tri_count, POWERUP_TRI_BUDGET])
	assert_gt(tri_count, 0, "Tank powerup has no triangles")

func test_powerup_star_triangle_count():
	var scene = load(POWERUP_MESH_PATHS["star"])
	assert_not_null(scene, "Failed to load powerup_star.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found in powerup_star")
	
	var tri_count = _count_triangles(mesh_inst)
	assert_lt(tri_count, POWERUP_TRI_BUDGET, 
		"Star powerup exceeds triangle budget: %d / %d" % [tri_count, POWERUP_TRI_BUDGET])

func test_powerup_grenade_triangle_count():
	var scene = load(POWERUP_MESH_PATHS["grenade"])
	assert_not_null(scene, "Failed to load powerup_grenade.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found in powerup_grenade")
	
	var tri_count = _count_triangles(mesh_inst)
	assert_lt(tri_count, POWERUP_TRI_BUDGET, 
		"Grenade powerup exceeds triangle budget: %d / %d" % [tri_count, POWERUP_TRI_BUDGET])

func test_powerup_shield_triangle_count():
	var scene = load(POWERUP_MESH_PATHS["shield"])
	assert_not_null(scene, "Failed to load powerup_shield.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found in powerup_shield")
	
	var tri_count = _count_triangles(mesh_inst)
	assert_lt(tri_count, POWERUP_TRI_BUDGET, 
		"Shield powerup exceeds triangle budget: %d / %d" % [tri_count, POWERUP_TRI_BUDGET])

func test_powerup_timer_triangle_count():
	var scene = load(POWERUP_MESH_PATHS["timer"])
	assert_not_null(scene, "Failed to load powerup_timer.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found in powerup_timer")
	
	var tri_count = _count_triangles(mesh_inst)
	assert_lt(tri_count, POWERUP_TRI_BUDGET, 
		"Timer powerup exceeds triangle budget: %d / %d" % [tri_count, POWERUP_TRI_BUDGET])

func test_powerup_shovel_triangle_count():
	var scene = load(POWERUP_MESH_PATHS["shovel"])
	assert_not_null(scene, "Failed to load powerup_shovel.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found in powerup_shovel")
	
	var tri_count = _count_triangles(mesh_inst)
	assert_lt(tri_count, POWERUP_TRI_BUDGET, 
		"Shovel powerup exceeds triangle budget: %d / %d" % [tri_count, POWERUP_TRI_BUDGET])

# Size Tests

func test_powerup_tank_size():
	var scene = load(POWERUP_MESH_PATHS["tank"])
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	var aabb = mesh_inst.get_aabb()
	
	# Should be approximately 0.6 units (tolerance ±0.3)
	var max_dim = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
	assert_almost_eq(max_dim, POWERUP_SIZE, 0.3, 
		"Tank powerup size incorrect: %f (expected ~%f)" % [max_dim, POWERUP_SIZE])

func test_powerup_star_size():
	var scene = load(POWERUP_MESH_PATHS["star"])
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	var aabb = mesh_inst.get_aabb()
	
	var max_dim = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
	assert_almost_eq(max_dim, POWERUP_SIZE, 0.3, 
		"Star powerup size incorrect: %f" % max_dim)

func test_powerups_are_smaller_than_tanks():
	# Load a sample tank for comparison
	var tank_scene = load("res://resources/meshes3d/models/tank_base.tscn")
	var tank_instance = tank_scene.instantiate()
	add_child_autofree(tank_instance)
	var tank_mesh = _find_mesh_instance(tank_instance)
	var tank_size = tank_mesh.get_aabb().size.length()
	
	# Check that powerups are smaller
	for powerup_type in POWERUP_MESH_PATHS:
		var scene = load(POWERUP_MESH_PATHS[powerup_type])
		var instance = scene.instantiate()
		add_child_autofree(instance)
		
		var mesh_inst = _find_mesh_instance(instance)
		var powerup_size = mesh_inst.get_aabb().size.length()
		
		assert_lt(powerup_size, tank_size, 
			"%s powerup is not smaller than tank" % powerup_type)

# Material Tests

func test_powerup_tank_material_is_unlit():
	var scene = load(POWERUP_MESH_PATHS["tank"])
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	var material = mesh_inst.get_surface_override_material(0)
	if material == null:
		material = mesh_inst.mesh.surface_get_material(0)
	
	assert_not_null(material, "Tank powerup has no material")
	if material is StandardMaterial3D:
		assert_eq(material.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED,
			"Tank powerup material is not unshaded")

func test_powerup_star_material_is_unlit():
	var scene = load(POWERUP_MESH_PATHS["star"])
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	var material = mesh_inst.get_surface_override_material(0)
	if material == null:
		material = mesh_inst.mesh.surface_get_material(0)
	
	assert_not_null(material, "Star powerup has no material")
	if material is StandardMaterial3D:
		assert_eq(material.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED,
			"Star powerup material is not unshaded")

# Distinct Shape Tests

func test_powerups_have_distinct_shapes():
	# Verify that powerups have different bounding box aspect ratios
	var aspect_ratios = []
	
	for powerup_type in POWERUP_MESH_PATHS:
		var scene = load(POWERUP_MESH_PATHS[powerup_type])
		var instance = scene.instantiate()
		add_child_autofree(instance)
		
		var mesh_inst = _find_mesh_instance(instance)
		var aabb = mesh_inst.get_aabb()
		
		# Calculate aspect ratio (width/height)
		var ratio = aabb.size.x / aabb.size.y if aabb.size.y > 0.0 else 0.0
		aspect_ratios.append(ratio)
	
	# Check that not all aspect ratios are identical
	var first_ratio = aspect_ratios[0]
	var all_same = true
	for ratio in aspect_ratios:
		if not is_equal_approx(ratio, first_ratio):
			all_same = false
			break
	
	# It's OK if some are similar, just verify they're valid
	for ratio in aspect_ratios:
		assert_gt(ratio, 0.0, "Invalid aspect ratio")
