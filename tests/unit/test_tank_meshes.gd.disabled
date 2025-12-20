extends GutTest

# Test suite for player and enemy tank 3D meshes
# Validates mesh existence, triangle counts, materials, and dimensions

const PLAYER_MESH_PATHS = [
	"res://resources/meshes3d/models/tank_base.tscn",
	"res://resources/meshes3d/models/tank_level1.tscn",
	"res://resources/meshes3d/models/tank_level2.tscn",
	"res://resources/meshes3d/models/tank_level3.tscn"
]

const ENEMY_MESH_PATHS = [
	"res://resources/meshes3d/models/enemy_basic.tscn",
	"res://resources/meshes3d/models/enemy_fast.tscn",
	"res://resources/meshes3d/models/enemy_power.tscn",
	"res://resources/meshes3d/models/enemy_armored.tscn"
]

const PLAYER_TRI_BUDGET = 500
const ENEMY_TRI_BUDGET = 300

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
				# No index array, count vertices
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

# Player Tank Tests

func test_player_tank_base_exists():
	assert_file_exists(PLAYER_MESH_PATHS[0])

func test_player_tank_level1_exists():
	assert_file_exists(PLAYER_MESH_PATHS[1])

func test_player_tank_level2_exists():
	assert_file_exists(PLAYER_MESH_PATHS[2])

func test_player_tank_level3_exists():
	assert_file_exists(PLAYER_MESH_PATHS[3])

func test_player_tank_base_triangle_count():
	var scene = load(PLAYER_MESH_PATHS[0])
	assert_not_null(scene, "Failed to load tank_base.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found in tank_base")
	
	var tri_count = _count_triangles(mesh_inst)
	assert_lt(tri_count, PLAYER_TRI_BUDGET, 
		"Player base tank exceeds triangle budget: %d / %d" % [tri_count, PLAYER_TRI_BUDGET])
	assert_gt(tri_count, 0, "Player base tank has no triangles")

func test_player_tank_level1_triangle_count():
	var scene = load(PLAYER_MESH_PATHS[1])
	assert_not_null(scene, "Failed to load tank_level1.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found in tank_level1")
	
	var tri_count = _count_triangles(mesh_inst)
	assert_lt(tri_count, PLAYER_TRI_BUDGET, 
		"Player level1 tank exceeds triangle budget: %d / %d" % [tri_count, PLAYER_TRI_BUDGET])

func test_player_tank_level2_triangle_count():
	var scene = load(PLAYER_MESH_PATHS[2])
	assert_not_null(scene, "Failed to load tank_level2.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found in tank_level2")
	
	var tri_count = _count_triangles(mesh_inst)
	assert_lt(tri_count, PLAYER_TRI_BUDGET, 
		"Player level2 tank exceeds triangle budget: %d / %d" % [tri_count, PLAYER_TRI_BUDGET])

func test_player_tank_level3_triangle_count():
	var scene = load(PLAYER_MESH_PATHS[3])
	assert_not_null(scene, "Failed to load tank_level3.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found in tank_level3")
	
	var tri_count = _count_triangles(mesh_inst)
	assert_lt(tri_count, PLAYER_TRI_BUDGET, 
		"Player level3 tank exceeds triangle budget: %d / %d" % [tri_count, PLAYER_TRI_BUDGET])

func test_player_tank_base_has_valid_aabb():
	var scene = load(PLAYER_MESH_PATHS[0])
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found")
	
	var aabb = mesh_inst.get_aabb()
	assert_gt(aabb.size.x, 0.0, "AABB width is invalid")
	assert_gt(aabb.size.y, 0.0, "AABB height is invalid")
	assert_gt(aabb.size.z, 0.0, "AABB depth is invalid")

func test_player_tank_base_dimensions():
	var scene = load(PLAYER_MESH_PATHS[0])
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	var aabb = mesh_inst.get_aabb()
	
	# Expected dimensions: ~1.0 × 0.5 × 1.0 (tolerance ±0.4 for depth due to tread overhang)
	assert_almost_eq(aabb.size.x, 1.0, 0.3, "Tank width incorrect")
	assert_almost_eq(aabb.size.y, 0.5, 0.3, "Tank height incorrect")
	assert_almost_eq(aabb.size.z, 1.0, 0.4, "Tank depth incorrect")

func test_player_tank_material_is_unlit():
	var scene = load(PLAYER_MESH_PATHS[0])
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found")
	
	var material = mesh_inst.get_surface_override_material(0)
	if material == null:
		material = mesh_inst.mesh.surface_get_material(0)
	
	assert_not_null(material, "Tank has no material")
	if material is StandardMaterial3D:
		assert_eq(material.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED,
			"Tank material is not unshaded")

# Enemy Tank Tests

func test_enemy_basic_exists():
	assert_file_exists(ENEMY_MESH_PATHS[0])

func test_enemy_fast_exists():
	assert_file_exists(ENEMY_MESH_PATHS[1])

func test_enemy_power_exists():
	assert_file_exists(ENEMY_MESH_PATHS[2])

func test_enemy_armored_exists():
	assert_file_exists(ENEMY_MESH_PATHS[3])

func test_enemy_basic_triangle_count():
	var scene = load(ENEMY_MESH_PATHS[0])
	assert_not_null(scene, "Failed to load enemy_basic.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found in enemy_basic")
	
	var tri_count = _count_triangles(mesh_inst)
	assert_lt(tri_count, ENEMY_TRI_BUDGET, 
		"Enemy basic exceeds triangle budget: %d / %d" % [tri_count, ENEMY_TRI_BUDGET])
	assert_gt(tri_count, 0, "Enemy basic has no triangles")

func test_enemy_fast_triangle_count():
	var scene = load(ENEMY_MESH_PATHS[1])
	assert_not_null(scene, "Failed to load enemy_fast.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found in enemy_fast")
	
	var tri_count = _count_triangles(mesh_inst)
	assert_lt(tri_count, ENEMY_TRI_BUDGET, 
		"Enemy fast exceeds triangle budget: %d / %d" % [tri_count, ENEMY_TRI_BUDGET])

func test_enemy_power_triangle_count():
	var scene = load(ENEMY_MESH_PATHS[2])
	assert_not_null(scene, "Failed to load enemy_power.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found in enemy_power")
	
	var tri_count = _count_triangles(mesh_inst)
	assert_lt(tri_count, ENEMY_TRI_BUDGET, 
		"Enemy power exceeds triangle budget: %d / %d" % [tri_count, ENEMY_TRI_BUDGET])

func test_enemy_armored_triangle_count():
	var scene = load(ENEMY_MESH_PATHS[3])
	assert_not_null(scene, "Failed to load enemy_armored.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found in enemy_armored")
	
	var tri_count = _count_triangles(mesh_inst)
	assert_lt(tri_count, ENEMY_TRI_BUDGET, 
		"Enemy armored exceeds triangle budget: %d / %d" % [tri_count, ENEMY_TRI_BUDGET])

func test_enemy_meshes_have_different_colors():
	var colors = []
	for path in ENEMY_MESH_PATHS:
		var scene = load(path)
		var instance = scene.instantiate()
		add_child_autofree(instance)
		
		var mesh_inst = _find_mesh_instance(instance)
		var material = mesh_inst.get_surface_override_material(0)
		if material == null:
			material = mesh_inst.mesh.surface_get_material(0)
		
		if material is StandardMaterial3D:
			colors.append(material.albedo_color)
	
	# Check that not all colors are the same
	assert_eq(colors.size(), 4, "Should have 4 enemy colors")
	var first_color = colors[0]
	var all_same = true
	for color in colors:
		if not color.is_equal_approx(first_color):
			all_same = false
			break
	
	assert_false(all_same, "All enemy tanks have the same color")

func test_enemy_basic_material_is_unlit():
	var scene = load(ENEMY_MESH_PATHS[0])
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	var material = mesh_inst.get_surface_override_material(0)
	if material == null:
		material = mesh_inst.mesh.surface_get_material(0)
	
	assert_not_null(material, "Enemy has no material")
	if material is StandardMaterial3D:
		assert_eq(material.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED,
			"Enemy material is not unshaded")
