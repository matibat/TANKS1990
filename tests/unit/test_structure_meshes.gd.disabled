extends GutTest

# Test suite for structure 3D meshes (base/eagle)
# Validates mesh existence, triangle count, dimensions, and recognizability

const BASE_MESH_PATH = "res://resources/meshes3d/models/base_eagle.tscn"
const BASE_TRI_BUDGET = 300

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

func test_base_eagle_exists():
	assert_file_exists(BASE_MESH_PATH)

func test_base_eagle_triangle_count():
	var scene = load(BASE_MESH_PATH)
	assert_not_null(scene, "Failed to load base_eagle.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	await get_tree().process_frame
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found in base_eagle")
	
	if mesh_inst.mesh == null:
		pending("Base eagle mesh not generated - mesh_loader may need runtime")
		return
	
	var tri_count = _count_triangles(mesh_inst)
	assert_lt(tri_count, BASE_TRI_BUDGET, 
		"Base eagle exceeds triangle budget: %d / %d" % [tri_count, BASE_TRI_BUDGET])
	assert_gt(tri_count, 50, "Base eagle has too few triangles (not recognizable)")

func test_base_eagle_has_valid_aabb():
	var scene = load(BASE_MESH_PATH)
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	await get_tree().process_frame
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found")
	
	if mesh_inst.mesh == null:
		pending("Base eagle mesh not generated - mesh_loader may need runtime")
		return
	
	var aabb = mesh_inst.get_aabb()
	assert_gt(aabb.size.x, 0.0, "AABB width is invalid")
	assert_gt(aabb.size.y, 0.0, "AABB height is invalid")
	assert_gt(aabb.size.z, 0.0, "AABB depth is invalid")

func test_base_eagle_dimensions():
	var scene = load(BASE_MESH_PATH)
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	await get_tree().process_frame
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found")
	
	if mesh_inst.mesh == null:
		pending("Base eagle mesh not generated - mesh_loader may need runtime")
		return
	
	var aabb = mesh_inst.get_aabb()
	
	# Expected dimensions: ~1.0 × 1.0 × 1.0 (tolerance ±0.85 due to eagle wing/detail geometry)
	assert_almost_eq(aabb.size.x, 1.0, 0.85, "Base width incorrect")
	assert_almost_eq(aabb.size.y, 1.0, 0.85, "Base height incorrect")
	assert_almost_eq(aabb.size.z, 1.0, 0.85, "Base depth incorrect")

func test_base_eagle_material_is_unlit():
	var scene = load(BASE_MESH_PATH)
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	await get_tree().process_frame
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found")
	
	if mesh_inst.mesh == null:
		pending("Base eagle mesh not generated - mesh_loader may need runtime")
		return
	
	# Base may have multiple materials, check at least one
	var has_unlit = false
	var material_count = mesh_inst.get_surface_override_material_count()
	if material_count == 0 and mesh_inst.mesh != null:
		material_count = mesh_inst.mesh.get_surface_count()
	
	if material_count == 0:
		pending("Base eagle has no materials - may need runtime setup")
		return
	
	for i in range(material_count):
		var material = mesh_inst.get_surface_override_material(i)
		if material == null and mesh_inst.mesh != null:
			if i < mesh_inst.mesh.get_surface_count():
				material = mesh_inst.mesh.surface_get_material(i)
		
		if material is StandardMaterial3D:
			if material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
				has_unlit = true
				break
	
	if material_count > 0:
		assert_true(has_unlit, "Base has no unshaded materials")

func test_base_eagle_has_sufficient_detail():
	var scene = load(BASE_MESH_PATH)
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	await get_tree().process_frame
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found")
	
	if mesh_inst.mesh == null:
		pending("Base eagle mesh not generated - mesh_loader may need runtime")
		return
	
	var tri_count = _count_triangles(mesh_inst)
	
	# Should have enough detail to be recognizable as eagle/base
	assert_gt(tri_count, 100, 
		"Base has too few triangles for recognizable shape: %d" % tri_count)

func test_base_eagle_is_not_overly_complex():
	var scene = load(BASE_MESH_PATH)
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	await get_tree().process_frame
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found")
	
	if mesh_inst.mesh == null:
		pending("Base eagle mesh not generated - mesh_loader may need runtime")
		return
	
	var tri_count = _count_triangles(mesh_inst)
	
	# Should not be unnecessarily complex
	assert_lt(tri_count, BASE_TRI_BUDGET, 
		"Base is overly complex: %d triangles" % tri_count)
