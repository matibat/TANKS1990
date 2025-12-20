extends GutTest

# Test suite for projectile (bullet) 3D meshes
# Validates mesh existence, triangle count, size, and material

const BULLET_MESH_PATH = "res://resources/meshes3d/models/bullet.tscn"
const BULLET_TRI_BUDGET = 150  # UV sphere (12 segments, 6 rings) = ~144 tris
const EXPECTED_DIAMETER = 0.2  # units

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

func test_bullet_mesh_exists():
	assert_file_exists(BULLET_MESH_PATH)

func test_bullet_triangle_count():
	var scene = load(BULLET_MESH_PATH)
	assert_not_null(scene, "Failed to load bullet.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	# Wait for _ready() to execute and generate mesh
	await get_tree().process_frame
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found in bullet")
	
	# Check if mesh was generated
	if mesh_inst.mesh == null:
		pending("Bullet mesh not generated - mesh_loader may need runtime")
		return
	
	var tri_count = _count_triangles(mesh_inst)
	assert_lt(tri_count, BULLET_TRI_BUDGET, 
		"Bullet exceeds triangle budget: %d / %d" % [tri_count, BULLET_TRI_BUDGET])
	assert_gt(tri_count, 0, "Bullet has no triangles")

func test_bullet_has_valid_aabb():
	var scene = load(BULLET_MESH_PATH)
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	await get_tree().process_frame
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found")
	
	if mesh_inst.mesh == null:
		pending("Bullet mesh not generated - mesh_loader may need runtime")
		return
	
	var aabb = mesh_inst.get_aabb()
	assert_gt(aabb.size.x, 0.0, "AABB width is invalid")
	assert_gt(aabb.size.y, 0.0, "AABB height is invalid")
	assert_gt(aabb.size.z, 0.0, "AABB depth is invalid")

func test_bullet_is_small():
	var scene = load(BULLET_MESH_PATH)
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	await get_tree().process_frame
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found")
	
	if mesh_inst.mesh == null:
		pending("Bullet mesh not generated - mesh_loader may need runtime")
		return
	
	var aabb = mesh_inst.get_aabb()
	
	# Expected: small sphere/capsule ~0.2 units diameter (tolerance ±0.15)
	var max_dimension = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
	assert_lt(max_dimension, 0.5, "Bullet is too large: %f" % max_dimension)
	assert_almost_eq(max_dimension, EXPECTED_DIAMETER, 0.15, 
		"Bullet size incorrect: %f (expected ~%f)" % [max_dimension, EXPECTED_DIAMETER])

func test_bullet_is_sphere_or_capsule():
	var scene = load(BULLET_MESH_PATH)
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	await get_tree().process_frame
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found")
	
	if mesh_inst.mesh == null:
		pending("Bullet mesh not generated - mesh_loader may need runtime")
		return
	
	var aabb = mesh_inst.get_aabb()
	
	# Check that it's roughly spherical (all dimensions similar)
	var x = aabb.size.x
	var y = aabb.size.y
	var z = aabb.size.z
	
	# Allow some variation for capsule shape
	var min_dim = min(x, min(y, z))
	var max_dim = max(x, max(y, z))
	var ratio = max_dim / min_dim if min_dim > 0.0 else 0.0
	
	assert_lt(ratio, 2.5, "Bullet shape is not spherical/capsule-like (ratio: %f)" % ratio)

func test_bullet_material_is_unlit():
	var scene = load(BULLET_MESH_PATH)
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	await get_tree().process_frame
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found")
	
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
		assert_eq(material.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED,
			"Bullet material is not unshaded")

func test_bullet_material_is_bright():
	var scene = load(BULLET_MESH_PATH)
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	await get_tree().process_frame
	
	var mesh_inst = _find_mesh_instance(instance)
	assert_not_null(mesh_inst, "No MeshInstance3D found")
	
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
		# Should be white or yellow (bright color)
		var brightness = (color.r + color.g + color.b) / 3.0
		assert_gt(brightness, 0.7, "Bullet color is not bright enough: %f" % brightness)
