## Test scene script for 3D assets
## Displays all generated meshes for visual validation

extends Node3D

# Preload generator scripts
const TankMeshGenerator = preload("res://resources/meshes3d/tank_mesh_generator.gd")
const BaseMeshGenerator = preload("res://resources/meshes3d/base_mesh_generator.gd")
const BulletMeshGenerator = preload("res://resources/meshes3d/bullet_mesh_generator.gd")
const TerrainMeshGenerator = preload("res://resources/meshes3d/terrain_mesh_generator.gd")

# Mesh generator references
var tank_gen
var base_gen
var bullet_gen
var terrain_gen

func _ready() -> void:
	# Initialize generators
	tank_gen = TankMeshGenerator.new()
	base_gen = BaseMeshGenerator.new()
	bullet_gen = BulletMeshGenerator.new()
	terrain_gen = TerrainMeshGenerator.new()
	
	# Generate and display all assets
	_setup_asset_gallery()

## Create gallery layout showing all 3D assets
func _setup_asset_gallery() -> void:
	var spacing := 2.5
	var row_spacing := 3.0
	
	# Row 1: Player tank (center)
	_add_mesh_display("Player Tank", tank_gen.generate_player_tank(), 
					  Vector3(0, 0, 0), 0.0)
	
	# Row 2: Enemy tanks (4 variants)
	for i in range(1, 5):
		var x_offset := (i - 2.5) * spacing
		_add_mesh_display("Enemy Type " + str(i), 
						  tank_gen.generate_enemy_tank(i),
						  Vector3(x_offset, 0, row_spacing), 
						  0.0)
	
	# Row 3: Base and bullets
	_add_mesh_display("Base/Eagle", base_gen.generate_base_mesh(),
					  Vector3(-spacing * 1.5, 0, row_spacing * 2), 0.0)
	
	_add_mesh_display("Bullet", bullet_gen.generate_bullet_mesh(),
					  Vector3(0, 0.5, row_spacing * 2), 0.0)
	
	_add_mesh_display("Bullet (Icosphere)", bullet_gen.generate_bullet_mesh_icosphere(),
					  Vector3(spacing, 0.5, row_spacing * 2), 0.0)
	
	# Row 4: Terrain tiles
	_add_mesh_display("Brick Tile", terrain_gen.generate_brick_tile(),
					  Vector3(-spacing * 1.5, 0, row_spacing * 3), 0.0)
	
	_add_mesh_display("Steel Tile", terrain_gen.generate_steel_tile(),
					  Vector3(-spacing * 0.5, 0, row_spacing * 3), 0.0)
	
	_add_mesh_display("Water Tile", terrain_gen.generate_water_tile(),
					  Vector3(spacing * 0.5, 0, row_spacing * 3), 0.0)
	
	_add_mesh_display("Forest Tile", terrain_gen.generate_forest_tile(),
					  Vector3(spacing * 1.5, 0, row_spacing * 3), 0.0)
	
	print("=== 3D Asset Gallery Generated ===")
	print("All meshes displayed. Use camera to inspect.")
	_print_triangle_counts()

## Add a mesh to the scene with label
func _add_mesh_display(label_text: String, mesh: ArrayMesh, position: Vector3, rotation_y: float) -> void:
	# Create mesh instance
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.rotation.y = deg_to_rad(rotation_y)
	add_child(mesh_instance)
	
	# Add label above mesh
	var label := Label3D.new()
	label.text = label_text
	label.position = position + Vector3(0, 1.5, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 24
	label.outline_size = 4
	add_child(label)

## Print triangle counts for all generated meshes
func _print_triangle_counts() -> void:
	print("\n=== Triangle Count Report ===")
	
	var meshes := {
		"Player Tank": tank_gen.generate_player_tank(),
		"Enemy Tank Type 1": tank_gen.generate_enemy_tank(1),
		"Enemy Tank Type 2": tank_gen.generate_enemy_tank(2),
		"Enemy Tank Type 3": tank_gen.generate_enemy_tank(3),
		"Enemy Tank Type 4": tank_gen.generate_enemy_tank(4),
		"Base/Eagle": base_gen.generate_base_mesh(),
		"Bullet (Sphere)": bullet_gen.generate_bullet_mesh(),
		"Bullet (Icosphere)": bullet_gen.generate_bullet_mesh_icosphere(),
		"Brick Tile": terrain_gen.generate_brick_tile(),
		"Steel Tile": terrain_gen.generate_steel_tile(),
		"Water Tile": terrain_gen.generate_water_tile(),
		"Forest Tile": terrain_gen.generate_forest_tile(),
	}
	
	var total_tris := 0
	for mesh_name in meshes:
		var mesh: ArrayMesh = meshes[mesh_name]
		var tri_count := _count_triangles(mesh)
		print("%s: %d triangles" % [mesh_name, tri_count])
		total_tris += tri_count
	
	print("\nTotal triangles (all assets): %d" % total_tris)
	print("Estimated scene budget (20 entities + 100 tiles): ~%d tris" % (20 * 400 + 100 * 12))
	print("=============================\n")

## Count triangles in a mesh
func _count_triangles(mesh: ArrayMesh) -> int:
	var total := 0
	for i in mesh.get_surface_count():
		var arrays = mesh.surface_get_arrays(i)
		if arrays.is_empty():
			continue
		
		var indices = arrays[Mesh.ARRAY_INDEX]
		if indices != null and indices.size() > 0:
			total += indices.size() / 3
		else:
			var vertices = arrays[Mesh.ARRAY_VERTEX]
			if vertices != null and vertices.size() > 0:
				total += vertices.size() / 3
	return total

## Get camera reference (if exists in parent scene)
func get_camera() -> Camera3D:
	var camera := get_viewport().get_camera_3d()
	if camera:
		return camera
	
	# Search children
	for child in get_children():
		if child is Camera3D:
			return child
	
	return null
