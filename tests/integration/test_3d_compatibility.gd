extends GutTest
## GUT 3D Compatibility Test
##
## Feature: 3D Scene Testing with GUT
## As a developer, I want to verify GUT can test 3D scenes
## So that 3D migration can maintain test-driven development

var test_node: Node3D

func before_each():
	test_node = Node3D.new()
	add_child(test_node)

func after_each():
	if test_node:
		test_node.queue_free()
		test_node = null


# Scenario: Basic 3D node instantiation
class TestNode3DInstantiation:
	extends GutTest
	
	func test_given_node3d_when_created_then_can_instantiate():
		# Given / When
		var node = Node3D.new()
		
		# Then
		assert_not_null(node, "Node3D should instantiate")
		assert_true(node is Node3D, "Should be Node3D type")
		node.free()
	
	func test_given_node3d_when_added_to_scene_then_has_transform():
		# Given
		var node = Node3D.new()
		add_child(node)
		
		# When
		var transform = node.transform
		
		# Then
		assert_not_null(transform, "Node3D should have transform")
		assert_eq(transform.origin, Vector3.ZERO, "Default origin should be zero")
		
		# Cleanup
		node.queue_free()


# Scenario: Vector3 position and rotation
class TestVector3Operations:
	extends GutTest
	
	func test_given_node3d_when_set_position_then_position_updates():
		# Given
		var node = Node3D.new()
		add_child(node)
		
		# When
		node.position = Vector3(10, 20, 30)
		
		# Then
		assert_eq(node.position.x, 10.0, "X position should be set")
		assert_eq(node.position.y, 20.0, "Y position should be set")
		assert_eq(node.position.z, 30.0, "Z position should be set")
		
		node.queue_free()
	
	func test_given_node3d_when_set_rotation_then_rotation_updates():
		# Given
		var node = Node3D.new()
		add_child(node)
		
		# When
		node.rotation_degrees = Vector3(0, 90, 0)
		
		# Then
		assert_almost_eq(node.rotation_degrees.y, 90.0, 0.1, "Y rotation should be 90°")
		
		node.queue_free()
	
	func test_given_node3d_when_translated_then_moves_relative():
		# Given
		var node = Node3D.new()
		add_child(node)
		node.position = Vector3(5, 5, 5)
		
		# When
		node.translate(Vector3(1, 2, 3))
		
		# Then
		assert_almost_eq(node.position.x, 6.0, 0.001, "X should move by 1")
		assert_almost_eq(node.position.y, 7.0, 0.001, "Y should move by 2")
		assert_almost_eq(node.position.z, 8.0, 0.001, "Z should move by 3")
		
		node.queue_free()


# Scenario: 3D scene hierarchy
class TestNode3DHierarchy:
	extends GutTest
	
	func test_given_parent_node_when_child_added_then_hierarchy_exists():
		# Given
		var parent = Node3D.new()
		var child = Node3D.new()
		add_child(parent)
		
		# When
		parent.add_child(child)
		
		# Then
		assert_eq(child.get_parent(), parent, "Child should have parent")
		assert_true(parent.get_children().has(child), "Parent should have child")
		
		parent.queue_free()
	
	func test_given_parent_moved_when_child_added_then_child_inherits_transform():
		# Given
		var parent = Node3D.new()
		var child = Node3D.new()
		add_child(parent)
		parent.position = Vector3(10, 0, 10)
		
		# When
		parent.add_child(child)
		child.position = Vector3(1, 0, 1)
		
		# Then (local vs global positions)
		assert_eq(child.position, Vector3(1, 0, 1), "Local position should be (1,0,1)")
		assert_almost_eq(child.global_position.x, 11.0, 0.001, "Global X should be 11")
		assert_almost_eq(child.global_position.z, 11.0, 0.001, "Global Z should be 11")
		
		parent.queue_free()


# Scenario: 3D collision shapes (basic)
class TestCollisionShapes3D:
	extends GutTest
	
	func test_given_staticbody3d_when_created_then_can_add_collision_shape():
		# Given
		var body = StaticBody3D.new()
		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		
		# When
		collision_shape.shape = box_shape
		body.add_child(collision_shape)
		add_child(body)
		
		# Then
		assert_not_null(collision_shape.shape, "CollisionShape3D should have shape")
		assert_true(collision_shape.shape is BoxShape3D, "Shape should be BoxShape3D")
		
		body.queue_free()
	
	func test_given_box_shape_when_set_size_then_dimensions_update():
		# Given
		var shape = BoxShape3D.new()
		
		# When
		shape.size = Vector3(2, 3, 4)
		
		# Then
		assert_eq(shape.size.x, 2.0, "X size should be 2")
		assert_eq(shape.size.y, 3.0, "Y size should be 3")
		assert_eq(shape.size.z, 4.0, "Z size should be 4")


# Scenario: MeshInstance3D basic usage
class TestMeshInstance3D:
	extends GutTest
	
	func test_given_mesh_instance_when_created_then_can_set_mesh():
		# Given
		var mesh_instance = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		
		# When
		mesh_instance.mesh = box_mesh
		add_child(mesh_instance)
		
		# Then
		assert_not_null(mesh_instance.mesh, "MeshInstance3D should have mesh")
		assert_true(mesh_instance.mesh is BoxMesh, "Mesh should be BoxMesh")
		
		mesh_instance.queue_free()
	
	func test_given_box_mesh_when_set_size_then_dimensions_update():
		# Given
		var box_mesh = BoxMesh.new()
		
		# When
		box_mesh.size = Vector3(1.5, 2.5, 3.5)
		
		# Then
		assert_almost_eq(box_mesh.size.x, 1.5, 0.001, "X size should be 1.5")
		assert_almost_eq(box_mesh.size.y, 2.5, 0.001, "Y size should be 2.5")
		assert_almost_eq(box_mesh.size.z, 3.5, 0.001, "Z size should be 3.5")


# Scenario: Camera3D basic setup
class TestCamera3D:
	extends GutTest
	
	func test_given_camera3d_when_created_then_has_projection():
		# Given / When
		var camera = Camera3D.new()
		add_child(camera)
		
		# Then
		assert_not_null(camera, "Camera3D should instantiate")
		# Default is perspective, we can change to orthogonal
		assert_true(
			camera.projection == Camera3D.PROJECTION_PERSPECTIVE or 
			camera.projection == Camera3D.PROJECTION_ORTHOGONAL,
			"Camera should have valid projection type"
		)
		
		camera.queue_free()
	
	func test_given_camera3d_when_set_orthogonal_then_projection_changes():
		# Given
		var camera = Camera3D.new()
		add_child(camera)
		
		# When
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 20.0
		
		# Then
		assert_eq(camera.projection, Camera3D.PROJECTION_ORTHOGONAL, "Should be orthogonal")
		assert_eq(camera.size, 20.0, "Orthogonal size should be 20")
		
		camera.queue_free()
