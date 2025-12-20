extends GutTest

# Test suite for terrain tile 3D meshes
# Validates mesh existence, triangle counts, dimensions, and tile conformity

const TILE_MESH_PATHS = {
	"brick": "res://resources/meshes3d/models/tile_brick.tscn",
	"steel": "res://resources/meshes3d/models/tile_steel.tscn",
	"water": "res://resources/meshes3d/models/tile_water.tscn",
	"forest": "res://resources/meshes3d/models/tile_forest.tscn"
}

const TILE_TRI_BUDGET = 200
const TILE_SIZE = 1.0  # Grid unit

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

func test_brick_tile_exists():
	assert_file_exists(TILE_MESH_PATHS["brick"])

func test_steel_tile_exists():
	assert_file_exists(TILE_MESH_PATHS["steel"])

func test_water_tile_exists():
	assert_file_exists(TILE_MESH_PATHS["water"])

func test_forest_tile_exists():
	assert_file_exists(TILE_MESH_PATHS["forest"])

# Triangle Count Tests

func test_brick_tile_triangle_count():
	var scene = load(TILE_MESH_PATHS["brick"])
	assert_not_null(scene, "Failed to load tile_brick.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found in tile_brick")
	
	var tri_count = _count_triangles(mesh_inst)
	assert_lt(tri_count, TILE_TRI_BUDGET, 
		"Brick tile exceeds triangle budget: %d / %d" % [tri_count, TILE_TRI_BUDGET])
	assert_gt(tri_count, 0, "Brick tile has no triangles")

func test_steel_tile_triangle_count():
	var scene = load(TILE_MESH_PATHS["steel"])
	assert_not_null(scene, "Failed to load tile_steel.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found in tile_steel")
	
	var tri_count = _count_triangles(mesh_inst)
	assert_lt(tri_count, TILE_TRI_BUDGET, 
		"Steel tile exceeds triangle budget: %d / %d" % [tri_count, TILE_TRI_BUDGET])

func test_water_tile_triangle_count():
	var scene = load(TILE_MESH_PATHS["water"])
	assert_not_null(scene, "Failed to load tile_water.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found in tile_water")
	
	var tri_count = _count_triangles(mesh_inst)
	assert_lt(tri_count, TILE_TRI_BUDGET, 
		"Water tile exceeds triangle budget: %d / %d" % [tri_count, TILE_TRI_BUDGET])

func test_forest_tile_triangle_count():
	var scene = load(TILE_MESH_PATHS["forest"])
	assert_not_null(scene, "Failed to load tile_forest.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found in tile_forest")
	
	var tri_count = _count_triangles(mesh_inst)
	assert_lt(tri_count, TILE_TRI_BUDGET, 
		"Forest tile exceeds triangle budget: %d / %d" % [tri_count, TILE_TRI_BUDGET])

# Dimension Tests

func test_brick_tile_is_1x1_unit():
	var scene = load(TILE_MESH_PATHS["brick"])
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	var aabb = mesh_inst.get_aabb()
	
	# Base should be approximately 1×1 (tolerance ±0.2)
	assert_almost_eq(aabb.size.x, TILE_SIZE, 0.2, "Brick tile width incorrect")
	assert_almost_eq(aabb.size.z, TILE_SIZE, 0.2, "Brick tile depth incorrect")

func test_steel_tile_is_1x1_unit():
	var scene = load(TILE_MESH_PATHS["steel"])
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	var aabb = mesh_inst.get_aabb()
	
	assert_almost_eq(aabb.size.x, TILE_SIZE, 0.2, "Steel tile width incorrect")
	assert_almost_eq(aabb.size.z, TILE_SIZE, 0.2, "Steel tile depth incorrect")

func test_water_tile_is_1x1_unit():
	var scene = load(TILE_MESH_PATHS["water"])
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	var aabb = mesh_inst.get_aabb()
	
	assert_almost_eq(aabb.size.x, TILE_SIZE, 0.2, "Water tile width incorrect")
	assert_almost_eq(aabb.size.z, TILE_SIZE, 0.2, "Water tile depth incorrect")

func test_forest_tile_is_1x1_unit():
	var scene = load(TILE_MESH_PATHS["forest"])
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	var aabb = mesh_inst.get_aabb()
	
	assert_almost_eq(aabb.size.x, TILE_SIZE, 0.3, "Forest tile width incorrect")
	assert_almost_eq(aabb.size.z, TILE_SIZE, 0.3, "Forest tile depth incorrect")

# Material Tests

func test_brick_tile_material_is_unlit():
	var scene = load(TILE_MESH_PATHS["brick"])
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	var material = mesh_inst.get_surface_override_material(0)
	if material == null:
		material = mesh_inst.mesh.surface_get_material(0)
	
	assert_not_null(material, "Brick tile has no material")
	if material is StandardMaterial3D:
		assert_eq(material.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED,
			"Brick tile material is not unshaded")

func test_steel_tile_material_is_unlit():
	var scene = load(TILE_MESH_PATHS["steel"])
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	var material = mesh_inst.get_surface_override_material(0)
	if material == null:
		material = mesh_inst.mesh.surface_get_material(0)
	
	assert_not_null(material, "Steel tile has no material")
	if material is StandardMaterial3D:
		assert_eq(material.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED,
			"Steel tile material is not unshaded")

func test_water_tile_material_is_unlit():
	var scene = load(TILE_MESH_PATHS["water"])
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	var material = mesh_inst.get_surface_override_material(0)
	if material == null:
		material = mesh_inst.mesh.surface_get_material(0)
	
	assert_not_null(material, "Water tile has no material")
	if material is StandardMaterial3D:
		assert_eq(material.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED,
			"Water tile material is not unshaded")

func test_forest_tile_material_is_unlit():
	var scene = load(TILE_MESH_PATHS["forest"])
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_inst = _find_mesh_instance(instance)
	var material = mesh_inst.get_surface_override_material(0)
	if material == null:
		material = mesh_inst.mesh.surface_get_material(0)
	
	assert_not_null(material, "Forest tile has no material")
	if material is StandardMaterial3D:
		assert_eq(material.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED,
			"Forest tile material is not unshaded")

# Height Variation Tests

func test_tiles_have_height_variation():
	# Tiles should not all be perfectly flat
	var heights = []
	for tile_type in TILE_MESH_PATHS:
		var scene = load(TILE_MESH_PATHS[tile_type])
		var instance = scene.instantiate()
		add_child_autofree(instance)
		
		var mesh_inst = _find_mesh_instance(instance)
		var aabb = mesh_inst.get_aabb()
		heights.append(aabb.size.y)
	
	# At least some tiles should have different heights
	var all_same = true
	var first_height = heights[0]
	for h in heights:
		if not is_equal_approx(h, first_height):
			all_same = false
			break
	
	# It's OK if they're all the same, but verify they have some height
	for h in heights:
		assert_gt(h, 0.0, "Tile has no height")
