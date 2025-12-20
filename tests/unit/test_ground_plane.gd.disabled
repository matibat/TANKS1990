extends GutTest

## Test suite for 3D ground plane
## Tests ground mesh, collision, material, and grid positioning

const GRID_SIZE := 26

var ground_scene: PackedScene
var ground_instance: Node3D
var static_body: StaticBody3D
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D


func before_each():
	# Load the ground plane scene before each test
	ground_scene = load("res://scenes3d/ground_plane.tscn")
	if ground_scene:
		ground_instance = ground_scene.instantiate()
		add_child_autofree(ground_instance)
		# Find components in the scene tree
		static_body = _find_node_of_type(ground_instance, StaticBody3D)
		mesh_instance = _find_node_of_type(ground_instance, MeshInstance3D)
		collision_shape = _find_node_of_type(ground_instance, CollisionShape3D)


func _find_node_of_type(node: Node, type) -> Node:
	if is_instance_of(node, type):
		return node
	for child in node.get_children():
		var result := _find_node_of_type(child, type)
		if result:
			return result
	return null


func test_ground_scene_loads():
	assert_not_null(ground_scene, "Ground plane scene should load successfully")


func test_ground_instance_exists():
	assert_not_null(ground_instance, "Ground instance should exist")


func test_static_body_exists():
	assert_not_null(static_body, "StaticBody3D should exist for ground collision")


func test_mesh_instance_exists():
	assert_not_null(mesh_instance, "MeshInstance3D should exist for ground visual")


func test_collision_shape_exists():
	assert_not_null(collision_shape, "CollisionShape3D should exist for ground collision")


func test_ground_at_y_zero():
	# Ground should be at Y=0 (ground plane)
	var pos := ground_instance.global_position
	assert_almost_eq(pos.y, 0.0, 0.1, "Ground should be at Y=0")


func test_ground_centered_on_grid():
	# Ground should be centered at grid midpoint (13, 0, 13)
	var pos := ground_instance.global_position
	var expected_center := GRID_SIZE / 2.0
	
	assert_almost_eq(pos.x, expected_center, 0.1, "Ground X should be centered at grid midpoint")
	assert_almost_eq(pos.z, expected_center, 0.1, "Ground Z should be centered at grid midpoint")


func test_mesh_is_plane():
	# Mesh should be a PlaneMesh
	var mesh := mesh_instance.mesh
	assert_not_null(mesh, "Mesh should be assigned")
	assert_true(mesh is PlaneMesh, "Mesh should be PlaneMesh type")


func test_plane_size_matches_grid():
	# Plane should be 26x26 to match grid
	var mesh := mesh_instance.mesh as PlaneMesh
	var size := mesh.size
	
	assert_almost_eq(size.x, float(GRID_SIZE), 0.1, "Plane width should match grid size")
	assert_almost_eq(size.y, float(GRID_SIZE), 0.1, "Plane depth should match grid size")


func test_collision_shape_is_box():
	# Collision shape should be BoxShape3D
	var shape := collision_shape.shape
	assert_not_null(shape, "Collision shape should be assigned")
	assert_true(shape is BoxShape3D, "Collision shape should be BoxShape3D")


func test_material_applied():
	# Mesh should have material assigned (for grid shader)
	assert_gt(
		mesh_instance.get_surface_override_material_count(),
		0,
		"Mesh should have material assigned"
	)
	
	var material := mesh_instance.get_surface_override_material(0)
	if material == null:
		# Check mesh material instead
		material = mesh_instance.mesh.surface_get_material(0)
	
	assert_not_null(material, "Material should be assigned for grid rendering")


func test_static_body_on_environment_layer():
	# StaticBody3D should be on layer 4 (Environment)
	assert_true(
		static_body.collision_layer & (1 << 3) != 0,
		"Static body should be on layer 4 (Environment, bit 3)"
	)


func test_ground_visible():
	# Ground mesh should be visible
	assert_true(mesh_instance.visible, "Ground mesh should be visible")
