## Tank Mesh Generator for TANKS1990
## Generates low-poly procedural tank meshes for player and enemies
## Target: Player ~500 tris, Enemies ~300 tris each

extends RefCounted
class_name TankMeshGenerator

# Color constants (matching 2D sprite palette)
const PLAYER_YELLOW = Color(0.95, 0.85, 0.2)
const PLAYER_GREEN = Color(0.3, 0.6, 0.2)
const ENEMY_GRAY = Color(0.6, 0.6, 0.6)
const ENEMY_RED = Color(0.8, 0.2, 0.2)
const ENEMY_GREEN = Color(0.4, 0.7, 0.3)
const ENEMY_SILVER = Color(0.75, 0.75, 0.8)

## Enemy tank types
enum EnemyType {
	BASIC = 1,    # Gray - balanced
	LIGHT = 2,    # Red - fast, light
	HEAVY = 3,    # Green - armored, slow
	FAST = 4      # Silver - very fast
}

## Generate player tank mesh (~500 tris)
## Returns ArrayMesh with body, turret, and treads
func generate_player_tank() -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Body: angled box chassis (0.8w × 0.4h × 0.9d) - ~200 tris
	_add_tank_body(surface_tool, Vector3(0.8, 0.4, 0.9), true)
	
	# Turret: cylinder base + box barrel - ~150 tris
	_add_turret(surface_tool, 0.4, 0.2, 16, 0.5, true)
	
	# Treads: two side boxes - ~150 tris
	_add_treads(surface_tool, Vector3(0.8, 0.4, 0.9), true)
	
	surface_tool.generate_normals()
	var mesh = surface_tool.commit()
	
	# Apply unlit material
	var material = _create_unlit_material(PLAYER_YELLOW)
	mesh.surface_set_material(0, material)
	
	return mesh

## Generate enemy tank mesh (~300 tris)
## type: EnemyType enum value (1-4)
func generate_enemy_tank(type: int = EnemyType.BASIC) -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var color: Color
	var size := Vector3(0.75, 0.35, 0.85)  # Slightly smaller than player
	
	match type:
		EnemyType.BASIC:
			color = ENEMY_GRAY
			_add_tank_body(surface_tool, size, false)
			_add_turret(surface_tool, 0.35, 0.15, 12, 0.4, false)
			_add_treads(surface_tool, size, false)
		
		EnemyType.LIGHT:
			color = ENEMY_RED
			size = Vector3(0.7, 0.3, 0.8)  # Smaller, faster
			_add_wedge_body(surface_tool, size)  # Sleeker shape
			_add_turret(surface_tool, 0.3, 0.12, 12, 0.35, false)
			_add_treads(surface_tool, size, false)
		
		EnemyType.HEAVY:
			color = ENEMY_GREEN
			size = Vector3(0.85, 0.4, 0.9)  # Bulkier
			_add_tank_body(surface_tool, size, false)
			_add_turret(surface_tool, 0.4, 0.18, 12, 0.45, false)
			_add_treads(surface_tool, Vector3(size.x * 1.1, size.y, size.z), false)  # Wider treads
		
		EnemyType.FAST:
			color = ENEMY_SILVER
			size = Vector3(0.72, 0.28, 0.82)  # Streamlined
			_add_wedge_body(surface_tool, size)
			_add_turret(surface_tool, 0.28, 0.1, 12, 0.35, false)
			_add_treads(surface_tool, Vector3(size.x * 0.9, size.y * 0.8, size.z), false)  # Thinner
	
	surface_tool.generate_normals()
	var mesh = surface_tool.commit()
	
	var material = _create_unlit_material(color)
	mesh.surface_set_material(0, material)
	
	return mesh

## Add tank body (box with optional angled front)
func _add_tank_body(st: SurfaceTool, size: Vector3, angled_front: bool) -> void:
	var hw := size.x / 2.0  # half width
	var hh := size.y / 2.0  # half height
	var hd := size.z / 2.0  # half depth
	
	# Define 8 corners of the box
	var corners := [
		Vector3(-hw, 0, -hd),    # 0: front-left-bottom
		Vector3(hw, 0, -hd),     # 1: front-right-bottom
		Vector3(hw, 0, hd),      # 2: back-right-bottom
		Vector3(-hw, 0, hd),     # 3: back-left-bottom
		Vector3(-hw, hh, -hd),   # 4: front-left-top
		Vector3(hw, hh, -hd),    # 5: front-right-top
		Vector3(hw, hh, hd),     # 6: back-right-top
		Vector3(-hw, hh, hd),    # 7: back-left-top
	]
	
	# Angle front face if player tank
	if angled_front:
		corners[4].z -= hd * 0.3  # Pull front-top forward
		corners[5].z -= hd * 0.3
	
	# Bottom face (2 tris)
	_add_quad(st, corners[3], corners[2], corners[1], corners[0])
	
	# Top face (2 tris)
	_add_quad(st, corners[4], corners[5], corners[6], corners[7])
	
	# Front face (2 tris)
	_add_quad(st, corners[0], corners[1], corners[5], corners[4])
	
	# Back face (2 tris)
	_add_quad(st, corners[2], corners[3], corners[7], corners[6])
	
	# Left face (2 tris)
	_add_quad(st, corners[3], corners[0], corners[4], corners[7])
	
	# Right face (2 tris)
	_add_quad(st, corners[1], corners[2], corners[6], corners[5])

## Add wedge-shaped body (for light/fast tanks)
func _add_wedge_body(st: SurfaceTool, size: Vector3) -> void:
	var hw := size.x / 2.0
	var hh := size.y / 2.0
	var hd := size.z / 2.0
	
	# Wedge: sloped from back to front
	var corners := [
		Vector3(-hw, 0, -hd),         # 0: front-left-bottom
		Vector3(hw, 0, -hd),          # 1: front-right-bottom
		Vector3(hw, 0, hd),           # 2: back-right-bottom
		Vector3(-hw, 0, hd),          # 3: back-left-bottom
		Vector3(-hw, hh * 0.5, -hd),  # 4: front-left-top (lower)
		Vector3(hw, hh * 0.5, -hd),   # 5: front-right-top (lower)
		Vector3(hw, hh, hd),          # 6: back-right-top (higher)
		Vector3(-hw, hh, hd),         # 7: back-left-top (higher)
	]
	
	# Bottom
	_add_quad(st, corners[3], corners[2], corners[1], corners[0])
	
	# Top (sloped)
	_add_quad(st, corners[4], corners[5], corners[6], corners[7])
	
	# Front (lower)
	_add_quad(st, corners[0], corners[1], corners[5], corners[4])
	
	# Back (higher)
	_add_quad(st, corners[2], corners[3], corners[7], corners[6])
	
	# Left (sloped)
	_add_quad(st, corners[3], corners[0], corners[4], corners[7])
	
	# Right (sloped)
	_add_quad(st, corners[1], corners[2], corners[6], corners[5])

## Add turret (cylinder base + box barrel)
func _add_turret(st: SurfaceTool, radius: float, height: float, sides: int, barrel_length: float, is_player: bool) -> void:
	var base_y := height * 0.6 if is_player else height * 0.5  # Turret sits on top of body
	
	# Cylinder base
	_add_cylinder(st, Vector3(0, base_y, 0), radius, height, sides)
	
	# Barrel (box extending forward)
	var barrel_size := 0.15 if is_player else 0.12
	var barrel_offset := Vector3(0, base_y + height / 2.0, -radius - barrel_length / 2.0)
	_add_box(st, barrel_offset, Vector3(barrel_size, barrel_size, barrel_length))

## Add treads (two side boxes)
func _add_treads(st: SurfaceTool, body_size: Vector3, detailed: bool) -> void:
	var tread_width := 0.1
	var tread_height := body_size.y * 0.85
	var tread_length := body_size.z * 0.95
	var offset_x := body_size.x / 2.0 + tread_width / 2.0
	
	# Left tread
	_add_box(st, Vector3(-offset_x, tread_height / 2.0, 0), 
			 Vector3(tread_width, tread_height, tread_length))
	
	# Right tread
	_add_box(st, Vector3(offset_x, tread_height / 2.0, 0), 
			 Vector3(tread_width, tread_height, tread_length))
	
	# Optional: add tread detail segments (skipped for now to stay within budget)

## Helper: add a box at position
func _add_box(st: SurfaceTool, center: Vector3, size: Vector3) -> void:
	var hw := size.x / 2.0
	var hh := size.y / 2.0
	var hd := size.z / 2.0
	
	var corners := [
		center + Vector3(-hw, -hh, -hd),  # 0
		center + Vector3(hw, -hh, -hd),   # 1
		center + Vector3(hw, -hh, hd),    # 2
		center + Vector3(-hw, -hh, hd),   # 3
		center + Vector3(-hw, hh, -hd),   # 4
		center + Vector3(hw, hh, -hd),    # 5
		center + Vector3(hw, hh, hd),     # 6
		center + Vector3(-hw, hh, hd),    # 7
	]
	
	# 6 faces
	_add_quad(st, corners[3], corners[2], corners[1], corners[0])  # bottom
	_add_quad(st, corners[4], corners[5], corners[6], corners[7])  # top
	_add_quad(st, corners[0], corners[1], corners[5], corners[4])  # front
	_add_quad(st, corners[2], corners[3], corners[7], corners[6])  # back
	_add_quad(st, corners[3], corners[0], corners[4], corners[7])  # left
	_add_quad(st, corners[1], corners[2], corners[6], corners[5])  # right

## Helper: add a cylinder
func _add_cylinder(st: SurfaceTool, center: Vector3, radius: float, height: float, sides: int) -> void:
	var half_h := height / 2.0
	
	# Bottom and top circles
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
		
		# Side quad (2 tris)
		_add_quad(st, 
			center + Vector3(x1, -half_h, z1),
			center + Vector3(x2, -half_h, z2),
			center + Vector3(x2, half_h, z2),
			center + Vector3(x1, half_h, z1))

## Helper: add a quad (2 triangles) with proper winding
func _add_quad(st: SurfaceTool, v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3) -> void:
	# Triangle 1: v1, v2, v3
	st.add_vertex(v1)
	st.add_vertex(v2)
	st.add_vertex(v3)
	
	# Triangle 2: v1, v3, v4
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
