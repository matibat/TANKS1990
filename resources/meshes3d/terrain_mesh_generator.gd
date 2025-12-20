## Terrain Mesh Generator for TANKS1990
## Generates low-poly terrain tile meshes (brick, steel, water, forest)
## Target: Brick/Steel ~12 tris, Water ~12 tris, Forest ~100 tris

extends RefCounted
class_name TerrainMeshGenerator

# Color constants
const BRICK_RED = Color(0.7, 0.3, 0.2)
const STEEL_GRAY = Color(0.5, 0.5, 0.5)
const WATER_BLUE = Color(0.2, 0.4, 0.7)
const FOREST_GREEN = Color(0.2, 0.5, 0.2)
const TREE_TRUNK_BROWN = Color(0.4, 0.25, 0.15)

## Terrain tile types
enum TileType {
	BRICK,
	STEEL,
	WATER,
	FOREST
}

## Generate brick wall tile mesh (~12 tris)
## Simple cube: 1×0.5×1 (width, height, depth)
func generate_brick_tile() -> ArrayMesh:
	var mesh = _create_cube_mesh(Vector3(1.0, 0.5, 1.0), Vector3(0, 0.25, 0))
	var material = _create_unlit_material(BRICK_RED)
	mesh.surface_set_material(0, material)
	return mesh

## Generate steel wall tile mesh (~12 tris)
## Cube: 1×0.6×1 (slightly taller than brick)
func generate_steel_tile() -> ArrayMesh:
	var mesh = _create_cube_mesh(Vector3(1.0, 0.6, 1.0), Vector3(0, 0.3, 0))
	var material = _create_unlit_material(STEEL_GRAY)
	
	# Add metallic look (still unlit but brighter)
	material.albedo_color = STEEL_GRAY * 1.2
	mesh.surface_set_material(0, material)
	return mesh

## Generate water tile mesh (~12 tris)
## Thin flat surface: 1×0.1×1
func generate_water_tile() -> ArrayMesh:
	var mesh = _create_cube_mesh(Vector3(1.0, 0.1, 1.0), Vector3(0, 0.05, 0))
	var material = _create_unlit_material(WATER_BLUE)
	
	# Optional: add slight transparency later
	mesh.surface_set_material(0, material)
	return mesh

## Generate forest tile mesh (~100 tris)
## Multiple simple trees (cones + cylinders)
func generate_forest_tile() -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate 4-5 simple trees in cluster
	var tree_positions := [
		Vector3(0.2, 0, 0.2),
		Vector3(-0.3, 0, 0.3),
		Vector3(0.35, 0, -0.25),
		Vector3(-0.15, 0, -0.3),
	]
	
	for pos in tree_positions:
		_add_simple_tree(surface_tool, pos, 0.15, 0.6)
	
	surface_tool.generate_normals()
	var mesh = surface_tool.commit()
	
	var material = _create_unlit_material(FOREST_GREEN)
	mesh.surface_set_material(0, material)
	
	return mesh

## Create a simple cube mesh
func _create_cube_mesh(size: Vector3, center: Vector3) -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	_add_box(surface_tool, center, size)
	
	surface_tool.generate_normals()
	return surface_tool.commit()

## Add a simple tree (cylinder trunk + cone foliage)
func _add_simple_tree(st: SurfaceTool, position: Vector3, trunk_radius: float, height: float) -> void:
	var trunk_height := height * 0.3
	var foliage_height := height * 0.7
	
	# Trunk (cylinder) - 8 sides for low-poly
	_add_cylinder(st, position + Vector3(0, trunk_height / 2.0, 0), 
				  trunk_radius * 0.5, trunk_height, 6)
	
	# Foliage (cone) - 8 sides
	_add_cone(st, position + Vector3(0, trunk_height + foliage_height / 2.0, 0),
			  trunk_radius * 2.0, foliage_height, 6)

## Helper: add a box
func _add_box(st: SurfaceTool, center: Vector3, size: Vector3) -> void:
	var hw := size.x / 2.0
	var hh := size.y / 2.0
	var hd := size.z / 2.0
	
	var corners := [
		center + Vector3(-hw, -hh, -hd), center + Vector3(hw, -hh, -hd),
		center + Vector3(hw, -hh, hd), center + Vector3(-hw, -hh, hd),
		center + Vector3(-hw, hh, -hd), center + Vector3(hw, hh, -hd),
		center + Vector3(hw, hh, hd), center + Vector3(-hw, hh, hd),
	]
	
	# 6 faces (12 tris total)
	_add_quad(st, corners[3], corners[2], corners[1], corners[0])  # bottom
	_add_quad(st, corners[4], corners[5], corners[6], corners[7])  # top
	_add_quad(st, corners[0], corners[1], corners[5], corners[4])  # front
	_add_quad(st, corners[2], corners[3], corners[7], corners[6])  # back
	_add_quad(st, corners[3], corners[0], corners[4], corners[7])  # left
	_add_quad(st, corners[1], corners[2], corners[6], corners[5])  # right

## Helper: add a cylinder
func _add_cylinder(st: SurfaceTool, center: Vector3, radius: float, height: float, sides: int) -> void:
	var half_h := height / 2.0
	
	for i in sides:
		var angle1 := (i / float(sides)) * TAU
		var angle2 := ((i + 1) / float(sides)) * TAU
		
		var x1 := cos(angle1) * radius
		var z1 := sin(angle1) * radius
		var x2 := cos(angle2) * radius
		var z2 := sin(angle2) * radius
		
		# Bottom cap
		st.add_vertex(center + Vector3(0, -half_h, 0))
		st.add_vertex(center + Vector3(x2, -half_h, z2))
		st.add_vertex(center + Vector3(x1, -half_h, z1))
		
		# Top cap
		st.add_vertex(center + Vector3(0, half_h, 0))
		st.add_vertex(center + Vector3(x1, half_h, z1))
		st.add_vertex(center + Vector3(x2, half_h, z2))
		
		# Side quad
		_add_quad(st,
			center + Vector3(x1, -half_h, z1),
			center + Vector3(x2, -half_h, z2),
			center + Vector3(x2, half_h, z2),
			center + Vector3(x1, half_h, z1))

## Helper: add a cone
func _add_cone(st: SurfaceTool, center: Vector3, radius: float, height: float, sides: int) -> void:
	var base_y := center.y - height / 2.0
	var tip := center + Vector3(0, height / 2.0, 0)
	
	for i in sides:
		var angle1 := (i / float(sides)) * TAU
		var angle2 := ((i + 1) / float(sides)) * TAU
		
		var x1 := cos(angle1) * radius
		var z1 := sin(angle1) * radius
		var x2 := cos(angle2) * radius
		var z2 := sin(angle2) * radius
		
		var base1 := Vector3(center.x + x1, base_y, center.z + z1)
		var base2 := Vector3(center.x + x2, base_y, center.z + z2)
		
		# Side triangle (from base to tip)
		st.add_vertex(base1)
		st.add_vertex(base2)
		st.add_vertex(tip)
		
		# Base triangle (closing bottom)
		st.add_vertex(Vector3(center.x, base_y, center.z))
		st.add_vertex(base2)
		st.add_vertex(base1)

## Helper: add a quad (2 triangles)
func _add_quad(st: SurfaceTool, v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3) -> void:
	st.add_vertex(v1)
	st.add_vertex(v2)
	st.add_vertex(v3)
	st.add_vertex(v1)
	st.add_vertex(v3)
	st.add_vertex(v4)

## Create unlit material with solid color
func _create_unlit_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.cull_mode = BaseMaterial3D.CULL_BACK
	return material
