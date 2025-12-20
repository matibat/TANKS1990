## Base/Eagle Mesh Generator for TANKS1990
## Generates the player base (eagle fortress) mesh
## Target: ~300 tris

extends RefCounted
class_name BaseMeshGenerator

# Color constants
const BASE_GRAY = Color(0.7, 0.7, 0.7)
const EAGLE_WHITE = Color(0.95, 0.95, 0.95)

## Generate base/eagle mesh (~300 tris)
## Returns ArrayMesh with foundation, walls, and eagle emblem
func generate_base_mesh() -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Foundation platform (1.8 × 1.8 × 0.3) - ~12 tris
	_add_box(surface_tool, Vector3(0, 0.15, 0), Vector3(1.8, 0.3, 1.8))
	
	# Four corner pillars - ~96 tris (24 each)
	var pillar_size := Vector3(0.2, 0.8, 0.2)
	var pillar_offset := 0.7
	_add_box(surface_tool, Vector3(-pillar_offset, 0.4, -pillar_offset), pillar_size)
	_add_box(surface_tool, Vector3(pillar_offset, 0.4, -pillar_offset), pillar_size)
	_add_box(surface_tool, Vector3(pillar_offset, 0.4, pillar_offset), pillar_size)
	_add_box(surface_tool, Vector3(-pillar_offset, 0.4, pillar_offset), pillar_size)
	
	# Central tower (0.6 × 0.6 × 0.6) - ~12 tris
	_add_box(surface_tool, Vector3(0, 0.6, 0), Vector3(0.6, 0.6, 0.6))
	
	# Eagle emblem (stylized) - ~150 tris
	_add_eagle_emblem(surface_tool, Vector3(0, 0.9, -0.35), 0.5)
	
	surface_tool.generate_normals()
	var mesh = surface_tool.commit()
	
	# Apply gray material to base structure
	var material = _create_unlit_material(BASE_GRAY)
	mesh.surface_set_material(0, material)
	
	return mesh

## Add eagle emblem (simplified bird shape)
## position: center point, scale: overall size multiplier
func _add_eagle_emblem(st: SurfaceTool, position: Vector3, scale: float) -> void:
	# Simplified eagle: body + wings + head
	# Body (center vertical bar)
	var body_width := 0.1 * scale
	var body_height := 0.4 * scale
	_add_box(st, position, Vector3(body_width, body_height, body_width))
	
	# Head (small sphere approximation - octahedron)
	var head_pos := position + Vector3(0, body_height / 2.0 + 0.1 * scale, 0)
	_add_octahedron(st, head_pos, 0.08 * scale)
	
	# Wings (two angled boxes extending outward)
	var wing_y := position.y
	var wing_size := Vector3(0.25 * scale, 0.05 * scale, 0.15 * scale)
	
	# Left wing
	_add_angled_box(st, position + Vector3(-0.25 * scale, wing_y, 0), 
					wing_size, 15.0)  # 15 degree upward angle
	
	# Right wing
	_add_angled_box(st, position + Vector3(0.25 * scale, wing_y, 0), 
					wing_size, -15.0)  # Mirror angle
	
	# Tail feathers (small triangular prisms)
	_add_tail_feather(st, position + Vector3(0, -body_height / 2.0 - 0.1 * scale, 0), scale)

## Add an octahedron (8 triangles) - simple sphere approximation
func _add_octahedron(st: SurfaceTool, center: Vector3, radius: float) -> void:
	var top := center + Vector3(0, radius, 0)
	var bottom := center + Vector3(0, -radius, 0)
	var front := center + Vector3(0, 0, -radius)
	var back := center + Vector3(0, 0, radius)
	var left := center + Vector3(-radius, 0, 0)
	var right := center + Vector3(radius, 0, 0)
	
	# 8 triangular faces
	_add_triangle(st, top, front, right)
	_add_triangle(st, top, right, back)
	_add_triangle(st, top, back, left)
	_add_triangle(st, top, left, front)
	_add_triangle(st, bottom, right, front)
	_add_triangle(st, bottom, back, right)
	_add_triangle(st, bottom, left, back)
	_add_triangle(st, bottom, front, left)

## Add an angled box (rotated around X axis)
func _add_angled_box(st: SurfaceTool, center: Vector3, size: Vector3, angle_deg: float) -> void:
	var angle_rad := deg_to_rad(angle_deg)
	var rot := Basis.from_euler(Vector3(angle_rad, 0, 0))
	
	var hw := size.x / 2.0
	var hh := size.y / 2.0
	var hd := size.z / 2.0
	
	var local_corners := [
		Vector3(-hw, -hh, -hd), Vector3(hw, -hh, -hd),
		Vector3(hw, -hh, hd), Vector3(-hw, -hh, hd),
		Vector3(-hw, hh, -hd), Vector3(hw, hh, -hd),
		Vector3(hw, hh, hd), Vector3(-hw, hh, hd),
	]
	
	# Transform and add
	var corners: Array[Vector3] = []
	for lc in local_corners:
		corners.append(center + rot * lc)
	
	# 6 faces
	_add_quad(st, corners[3], corners[2], corners[1], corners[0])
	_add_quad(st, corners[4], corners[5], corners[6], corners[7])
	_add_quad(st, corners[0], corners[1], corners[5], corners[4])
	_add_quad(st, corners[2], corners[3], corners[7], corners[6])
	_add_quad(st, corners[3], corners[0], corners[4], corners[7])
	_add_quad(st, corners[1], corners[2], corners[6], corners[5])

## Add tail feather (triangular shape)
func _add_tail_feather(st: SurfaceTool, position: Vector3, scale: float) -> void:
	var width := 0.15 * scale
	var length := 0.2 * scale
	var thickness := 0.02 * scale
	
	# Three vertices forming triangle base
	var v1 := position + Vector3(-width / 2.0, 0, 0)
	var v2 := position + Vector3(width / 2.0, 0, 0)
	var v3 := position + Vector3(0, -length, 0)
	
	# Front face
	_add_triangle(st, v1, v2, v3)
	
	# Back face (with thickness)
	var v1_back := v1 + Vector3(0, 0, thickness)
	var v2_back := v2 + Vector3(0, 0, thickness)
	var v3_back := v3 + Vector3(0, 0, thickness)
	_add_triangle(st, v2_back, v1_back, v3_back)
	
	# Side edges
	_add_quad(st, v1, v2, v2_back, v1_back)
	_add_quad(st, v2, v3, v3_back, v2_back)
	_add_quad(st, v3, v1, v1_back, v3_back)

## Helper: add a box at position
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
	
	_add_quad(st, corners[3], corners[2], corners[1], corners[0])
	_add_quad(st, corners[4], corners[5], corners[6], corners[7])
	_add_quad(st, corners[0], corners[1], corners[5], corners[4])
	_add_quad(st, corners[2], corners[3], corners[7], corners[6])
	_add_quad(st, corners[3], corners[0], corners[4], corners[7])
	_add_quad(st, corners[1], corners[2], corners[6], corners[5])

## Helper: add a quad (2 triangles)
func _add_quad(st: SurfaceTool, v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3) -> void:
	st.add_vertex(v1)
	st.add_vertex(v2)
	st.add_vertex(v3)
	st.add_vertex(v1)
	st.add_vertex(v3)
	st.add_vertex(v4)

## Helper: add a triangle
func _add_triangle(st: SurfaceTool, v1: Vector3, v2: Vector3, v3: Vector3) -> void:
	st.add_vertex(v1)
	st.add_vertex(v2)
	st.add_vertex(v3)

## Create unlit material with solid color
func _create_unlit_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.cull_mode = BaseMaterial3D.CULL_BACK
	return material
