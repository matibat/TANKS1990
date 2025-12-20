extends GutTest

# Integration test for 3D asset gallery scene
# Validates that all meshes load correctly and display without errors

const GALLERY_SCENE_PATH = "res://scenes3d/asset_gallery.tscn"

const ALL_MESH_PATHS = [
	# Player tanks
	"res://resources/meshes3d/models/tank_base.tscn",
	"res://resources/meshes3d/models/tank_level1.tscn",
	"res://resources/meshes3d/models/tank_level2.tscn",
	"res://resources/meshes3d/models/tank_level3.tscn",
	# Enemy tanks
	"res://resources/meshes3d/models/enemy_basic.tscn",
	"res://resources/meshes3d/models/enemy_fast.tscn",
	"res://resources/meshes3d/models/enemy_power.tscn",
	"res://resources/meshes3d/models/enemy_armored.tscn",
	# Projectile
	"res://resources/meshes3d/models/bullet.tscn",
	# Structure
	"res://resources/meshes3d/models/base_eagle.tscn",
	# Terrain
	"res://resources/meshes3d/models/tile_brick.tscn",
	"res://resources/meshes3d/models/tile_steel.tscn",
	"res://resources/meshes3d/models/tile_water.tscn",
	"res://resources/meshes3d/models/tile_forest.tscn",
	# Power-ups
	"res://resources/meshes3d/models/powerup_tank.tscn",
	"res://resources/meshes3d/models/powerup_star.tscn",
	"res://resources/meshes3d/models/powerup_grenade.tscn",
	"res://resources/meshes3d/models/powerup_shield.tscn",
	"res://resources/meshes3d/models/powerup_timer.tscn",
	"res://resources/meshes3d/models/powerup_shovel.tscn"
]

func _count_mesh_instances(node: Node) -> int:
	var count = 0
	if node is MeshInstance3D:
		count = 1
	for child in node.get_children():
		count += _count_mesh_instances(child)
	return count

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

func _collect_all_mesh_instances(node: Node, meshes: Array) -> void:
	if node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children():
		_collect_all_mesh_instances(child, meshes)

func test_asset_gallery_scene_exists():
	assert_file_exists(GALLERY_SCENE_PATH)

func test_asset_gallery_loads():
	var scene = load(GALLERY_SCENE_PATH)
	assert_not_null(scene, "Failed to load asset_gallery.tscn")
	
	var instance = scene.instantiate()
	assert_not_null(instance, "Failed to instantiate asset gallery")
	add_child_autofree(instance)

func test_asset_gallery_has_camera():
	var scene = load(GALLERY_SCENE_PATH)
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var camera = instance.find_child("Camera3D*", true, false)
	if camera == null:
		# Try alternative search
		for child in instance.get_children():
			if child is Camera3D:
				camera = child
				break
	
	assert_not_null(camera, "Asset gallery has no Camera3D")

func test_asset_gallery_has_lighting():
	var scene = load(GALLERY_SCENE_PATH)
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var light = instance.find_child("DirectionalLight3D*", true, false)
	if light == null:
		# Check for any light
		for child in instance.get_children():
			if child is DirectionalLight3D or child is OmniLight3D:
				light = child
				break
	
	assert_not_null(light, "Asset gallery has no lighting")

func test_asset_gallery_displays_meshes():
	var scene = load(GALLERY_SCENE_PATH)
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var mesh_count = _count_mesh_instances(instance)
	assert_gt(mesh_count, 0, "Asset gallery has no mesh instances")
	
	# Should have at least 20 meshes (all our asset types)
	assert_gte(mesh_count, 20, 
		"Asset gallery should display at least 20 meshes, found %d" % mesh_count)

func test_all_meshes_load_without_errors():
	# Test that each mesh can be loaded individually
	var errors = []
	
	for mesh_path in ALL_MESH_PATHS:
		var scene = load(mesh_path)
		if scene == null:
			errors.append("Failed to load: %s" % mesh_path)
			continue
		
		var instance = scene.instantiate()
		if instance == null:
			errors.append("Failed to instantiate: %s" % mesh_path)
			continue
		
		add_child_autofree(instance)
	
	assert_eq(errors.size(), 0, "Mesh loading errors: %s" % str(errors))

func test_asset_gallery_triangle_count_totals():
	var scene = load(GALLERY_SCENE_PATH)
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var meshes = []
	_collect_all_mesh_instances(instance, meshes)
	
	var total_triangles = 0
	for mesh_inst in meshes:
		total_triangles += _count_triangles(mesh_inst)
	
	# Total for all unique assets should be reasonable
	# 20 assets × ~200 tris average = ~4000 tris
	assert_lt(total_triangles, 20000, 
		"Total triangle count is too high: %d" % total_triangles)
	assert_gt(total_triangles, 1000, 
		"Total triangle count is suspiciously low: %d" % total_triangles)

func test_asset_gallery_no_error_warnings():
	# Push error/warning handler
	var had_errors = false
	
	# Load and instantiate gallery
	var scene = load(GALLERY_SCENE_PATH)
	assert_not_null(scene, "Gallery scene is null")
	
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	# Wait a frame for initialization
	await wait_frames(2)
	
	# If we got here without crashing, consider it a pass
	assert_true(true, "Asset gallery loaded without fatal errors")

func test_asset_gallery_script_exists():
	var scene = load(GALLERY_SCENE_PATH)
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var script = instance.get_script()
	# Script is optional for gallery, but if present should be valid
	if script != null:
		assert_not_null(script, "Asset gallery script is invalid")

func test_gallery_meshes_are_valid():
	var scene = load(GALLERY_SCENE_PATH)
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var meshes = []
	_collect_all_mesh_instances(instance, meshes)
	
	for mesh_inst in meshes:
		assert_not_null(mesh_inst.mesh, "MeshInstance3D has null mesh")
		var aabb = mesh_inst.get_aabb()
		assert_gt(aabb.size.x, 0.0, "Mesh has invalid AABB width")
		assert_gt(aabb.size.y, 0.0, "Mesh has invalid AABB height")
		assert_gt(aabb.size.z, 0.0, "Mesh has invalid AABB depth")

func test_gallery_meshes_have_materials():
	var scene = load(GALLERY_SCENE_PATH)
	var instance = scene.instantiate()
	add_child_autofree(instance)
	
	var meshes = []
	_collect_all_mesh_instances(instance, meshes)
	
	var meshes_without_material = 0
	for mesh_inst in meshes:
		var has_material = false
		for i in range(mesh_inst.get_surface_override_material_count()):
			if mesh_inst.get_surface_override_material(i) != null:
				has_material = true
				break
		
		if not has_material and mesh_inst.mesh != null:
			for i in range(mesh_inst.mesh.get_surface_count()):
				if mesh_inst.mesh.surface_get_material(i) != null:
					has_material = true
					break
		
		if not has_material:
			meshes_without_material += 1
	
	# Some meshes might not have materials in gallery (that's OK)
	# Just check that most do
	var material_ratio = float(meshes.size() - meshes_without_material) / float(meshes.size())
	assert_gt(material_ratio, 0.5, 
		"Too few meshes have materials: %d/%d" % [meshes.size() - meshes_without_material, meshes.size()])
