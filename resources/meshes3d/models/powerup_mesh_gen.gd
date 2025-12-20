@tool
extends MeshInstance3D

## Procedural power-up mesh generator
## Generates simple geometric shapes for power-up icons

@export_enum("tank", "star", "grenade", "shield", "timer", "shovel") var powerup_type: String = "star"
@export var material_path: String = ""

func _ready():
	mesh = _generate_powerup_mesh(powerup_type)
	
	if not material_path.is_empty() and ResourceLoader.exists(material_path):
		var mat = load(material_path)
		set_surface_override_material(0, mat)

func _generate_powerup_mesh(type: String) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	match type:
		"star":
			_add_star(st, 0.3, 0.15, 5)
		"grenade", "sphere":
			_add_sphere(st, 0.15, 8, 8)
		"shield":
			_add_shield(st, 0.25, 0.3)
		"tank":
			_add_box(st, Vector3(0.3, 0.15, 0.3))
		"timer":
			_add_cylinder(st, 0.15, 0.2, 12)
		"shovel":
			_add_box(st, Vector3(0.2, 0.3, 0.15))
		_:
			_add_box(st, Vector3(0.2, 0.2, 0.2))
	
	st.generate_normals()
	return st.commit()

func _add_star(st: SurfaceTool, outer_radius: float, inner_radius: float, points: int):
	var angle_step = TAU / points
	var extrude = 0.1
	for i in range(points):
		var angle1 = i * angle_step
		var angle2 = (i + 0.5) * angle_step
		var angle3 = (i + 1) * angle_step
		var outer1 = Vector3(cos(angle1) * outer_radius, 0, sin(angle1) * outer_radius)
		var inner = Vector3(cos(angle2) * inner_radius, 0, sin(angle2) * inner_radius)
		var outer2 = Vector3(cos(angle3) * outer_radius, 0, sin(angle3) * outer_radius)
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(outer1)
		st.add_vertex(inner)
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(inner)
		st.add_vertex(outer2)

func _add_sphere(st: SurfaceTool, radius: float, rings: int, segments: int):
	for r in range(rings):
		for s in range(segments):
			var theta1 = r * PI / rings
			var theta2 = (r + 1) * PI / rings
			var phi1 = s * TAU / segments
			var phi2 = (s + 1) * TAU / segments
			var v1 = Vector3(sin(theta1) * cos(phi1), cos(theta1), sin(theta1) * sin(phi1)) * radius
			var v2 = Vector3(sin(theta1) * cos(phi2), cos(theta1), sin(theta1) * sin(phi2)) * radius
			var v3 = Vector3(sin(theta2) * cos(phi2), cos(theta2), sin(theta2) * sin(phi2)) * radius
			var v4 = Vector3(sin(theta2) * cos(phi1), cos(theta2), sin(theta2) * sin(phi1)) * radius
			if r != 0:
				st.add_vertex(v1)
				st.add_vertex(v2)
				st.add_vertex(v3)
			if r != rings - 1:
				st.add_vertex(v1)
				st.add_vertex(v3)
				st.add_vertex(v4)

func _add_shield(st: SurfaceTool, width: float, height: float):
	var points = [
		Vector3(-width, height, 0), Vector3(width, height, 0),
		Vector3(width, 0, 0), Vector3(width/2, -height/3, 0),
		Vector3(0, -height, 0), Vector3(-width/2, -height/3, 0),
		Vector3(-width, 0, 0)
	]
	for i in range(1, points.size() - 1):
		st.add_vertex(points[0])
		st.add_vertex(points[i])
		st.add_vertex(points[i + 1])
	var extrude = 0.05
	for i in range(points.size()):
		var p1 = points[i]
		var p2 = points[(i + 1) % points.size()]
		st.add_vertex(p1)
		st.add_vertex(p2)
		st.add_vertex(p2 + Vector3(0, 0, extrude))
		st.add_vertex(p1)
		st.add_vertex(p2 + Vector3(0, 0, extrude))
		st.add_vertex(p1 + Vector3(0, 0, extrude))

func _add_cylinder(st: SurfaceTool, radius: float, height: float, segments: int):
	for i in range(segments):
		var angle1 = i * TAU / segments
		var angle2 = (i + 1) * TAU / segments
		var p1 = Vector3(cos(angle1) * radius, 0, sin(angle1) * radius)
		var p2 = Vector3(cos(angle2) * radius, 0, sin(angle2) * radius)
		var p3 = p2 + Vector3(0, height, 0)
		var p4 = p1 + Vector3(0, height, 0)
		st.add_vertex(p1)
		st.add_vertex(p2)
		st.add_vertex(p3)
		st.add_vertex(p1)
		st.add_vertex(p3)
		st.add_vertex(p4)
		st.add_vertex(Vector3(0, 0, 0))
		st.add_vertex(p2)
		st.add_vertex(p1)
		st.add_vertex(Vector3(0, height, 0))
		st.add_vertex(p4)
		st.add_vertex(p3)

func _add_box(st: SurfaceTool, size: Vector3):
	var hs = size / 2.0
	var verts = [
		Vector3(-hs.x, -hs.y, hs.z), Vector3(hs.x, -hs.y, hs.z), Vector3(hs.x, hs.y, hs.z),
		Vector3(-hs.x, -hs.y, hs.z), Vector3(hs.x, hs.y, hs.z), Vector3(-hs.x, hs.y, hs.z),
		Vector3(hs.x, -hs.y, -hs.z), Vector3(-hs.x, -hs.y, -hs.z), Vector3(-hs.x, hs.y, -hs.z),
		Vector3(hs.x, -hs.y, -hs.z), Vector3(-hs.x, hs.y, -hs.z), Vector3(hs.x, hs.y, -hs.z),
		Vector3(-hs.x, hs.y, hs.z), Vector3(hs.x, hs.y, hs.z), Vector3(hs.x, hs.y, -hs.z),
		Vector3(-hs.x, hs.y, hs.z), Vector3(hs.x, hs.y, -hs.z), Vector3(-hs.x, hs.y, -hs.z),
		Vector3(-hs.x, -hs.y, -hs.z), Vector3(hs.x, -hs.y, -hs.z), Vector3(hs.x, -hs.y, hs.z),
		Vector3(-hs.x, -hs.y, -hs.z), Vector3(hs.x, -hs.y, hs.z), Vector3(-hs.x, -hs.y, hs.z),
		Vector3(-hs.x, -hs.y, -hs.z), Vector3(-hs.x, -hs.y, hs.z), Vector3(-hs.x, hs.y, hs.z),
		Vector3(-hs.x, -hs.y, -hs.z), Vector3(-hs.x, hs.y, hs.z), Vector3(-hs.x, hs.y, -hs.z),
		Vector3(hs.x, -hs.y, hs.z), Vector3(hs.x, -hs.y, -hs.z), Vector3(hs.x, hs.y, -hs.z),
		Vector3(hs.x, -hs.y, hs.z), Vector3(hs.x, hs.y, -hs.z), Vector3(hs.x, hs.y, hs.z)
	]
	for v in verts:
		st.add_vertex(v)
