class_name GridOverlay
extends Node3D
## GridOverlay - Visual debug overlay for 26×26 tile grid
## Toggle visibility with F3 key for debugging entity positions

## Grid configuration
const GRID_SIZE := 26 # 26x26 tiles
const TILE_SIZE_PIXELS := 16 # Each tile is 16 pixels
const TILE_SIZE_WORLD := 1.0 / 16.0 # 0.0625 world units per pixel
const HALF_TILE := 8 # Half-tile is 8 pixels

## Colors
const GRID_COLOR := Color(0.3, 0.3, 0.3, 0.5) # Gray for main grid lines
const HALF_TILE_COLOR := Color(0.2, 0.5, 0.2, 0.3) # Green for half-tile marks

var _grid_mesh_instance: MeshInstance3D

func _ready() -> void:
	# Start hidden by default
	visible = false
	
	# Create grid mesh
	_create_grid_mesh()
	
	print("GridOverlay ready - Press F3 to toggle")

## Handle F3 input to toggle visibility
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_F3 and event.pressed and not event.echo:
		visible = !visible
		print("Grid overlay: ", "visible" if visible else "hidden")

## Create the grid mesh with lines
func _create_grid_mesh() -> void:
	var immediate_mesh := ImmediateMesh.new()
	_grid_mesh_instance = MeshInstance3D.new()
	_grid_mesh_instance.mesh = immediate_mesh
	add_child(_grid_mesh_instance)
	
	# Create material for grid lines
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_grid_mesh_instance.material_override = material
	
	# Draw grid lines
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	# Draw main tile grid (26x26 tiles)
	for i in range(GRID_SIZE + 1):
		var world_pos := float(i) * TILE_SIZE_PIXELS * TILE_SIZE_WORLD
		
		# Vertical lines (along Z axis)
		immediate_mesh.surface_set_color(GRID_COLOR)
		immediate_mesh.surface_add_vertex(Vector3(world_pos, 0.01, 0))
		immediate_mesh.surface_add_vertex(Vector3(world_pos, 0.01, GRID_SIZE * TILE_SIZE_PIXELS * TILE_SIZE_WORLD))
		
		# Horizontal lines (along X axis)
		immediate_mesh.surface_add_vertex(Vector3(0, 0.01, world_pos))
		immediate_mesh.surface_add_vertex(Vector3(GRID_SIZE * TILE_SIZE_PIXELS * TILE_SIZE_WORLD, 0.01, world_pos))
	
	# Draw half-tile marks (8px intervals)
	for i in range(GRID_SIZE * 2 + 1):
		var world_pos := float(i) * HALF_TILE * TILE_SIZE_WORLD
		
		# Skip positions that coincide with main grid
		if i % 2 == 0:
			continue
		
		# Vertical half-tile lines (shorter, different color)
		immediate_mesh.surface_set_color(HALF_TILE_COLOR)
		for j in range(GRID_SIZE):
			var z_start := float(j) * TILE_SIZE_PIXELS * TILE_SIZE_WORLD
			var z_end := z_start + TILE_SIZE_PIXELS * TILE_SIZE_WORLD * 0.2 # Short marks
			immediate_mesh.surface_add_vertex(Vector3(world_pos, 0.01, z_start))
			immediate_mesh.surface_add_vertex(Vector3(world_pos, 0.01, z_end))
		
		# Horizontal half-tile lines (shorter, different color)
		for j in range(GRID_SIZE):
			var x_start := float(j) * TILE_SIZE_PIXELS * TILE_SIZE_WORLD
			var x_end := x_start + TILE_SIZE_PIXELS * TILE_SIZE_WORLD * 0.2 # Short marks
			immediate_mesh.surface_add_vertex(Vector3(x_start, 0.01, world_pos))
			immediate_mesh.surface_add_vertex(Vector3(x_end, 0.01, world_pos))
	
	immediate_mesh.surface_end()
