## Bullet Mesh Generator for TANKS1990
## Generates simple low-poly bullet projectile mesh
## Target: ~50 tris (UV sphere with 16 sides, 8 rings)

extends RefCounted
class_name BulletMeshGenerator

# Color constants
const BULLET_WHITE = Color(1.0, 1.0, 1.0)

## Generate bullet mesh (~50 tris)
## Returns ArrayMesh - simple sphere
func generate_bullet_mesh() -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var radius := 0.075  # 0.15 unit diameter
	var rings := 6       # Vertical subdivisions (reduced for low-poly)
	var radial_segments := 12  # Horizontal subdivisions
	
	_add_uv_sphere(surface_tool, Vector3.ZERO, radius, rings, radial_segments)
	
	surface_tool.generate_normals()
	var mesh = surface_tool.commit()
	
	var material = _create_unlit_material(BULLET_WHITE)
	mesh.surface_set_material(0, material)
	
	return mesh

## Add UV sphere mesh
func _add_uv_sphere(st: SurfaceTool, center: Vector3, radius: float, rings: int, segments: int) -> void:
	# Generate vertices in spherical coordinates
	# Rings: latitude lines from top to bottom
	# Segments: longitude lines around circumference
	
	for ring in range(rings + 1):
		var theta := (ring / float(rings)) * PI  # 0 to PI (top to bottom)
		var sin_theta := sin(theta)
		var cos_theta := cos(theta)
		
		for segment in range(segments + 1):
			var phi := (segment / float(segments)) * TAU  # 0 to 2PI (around)
			var sin_phi := sin(phi)
			var cos_phi := cos(phi)
			
			var x := cos_phi * sin_theta
			var y := cos_theta
			var z := sin_phi * sin_theta
			
			var vertex := center + Vector3(x, y, z) * radius
			
			# Build triangles (skip last segment column and last ring row for indices)
			if ring < rings and segment < segments:
				var current := ring * (segments + 1) + segment
				var next := current + segments + 1
				
				# First triangle of quad
				st.add_vertex(vertex)
				st.add_vertex(center + Vector3(
					cos(phi) * sin((ring + 1) / float(rings) * PI),
					cos((ring + 1) / float(rings) * PI),
					sin(phi) * sin((ring + 1) / float(rings) * PI)
				) * radius)
				st.add_vertex(center + Vector3(
					cos((segment + 1) / float(segments) * TAU) * sin_theta,
					cos_theta,
					sin((segment + 1) / float(segments) * TAU) * sin_theta
				) * radius)
				
				# Second triangle of quad
				st.add_vertex(center + Vector3(
					cos((segment + 1) / float(segments) * TAU) * sin_theta,
					cos_theta,
					sin((segment + 1) / float(segments) * TAU) * sin_theta
				) * radius)
				st.add_vertex(center + Vector3(
					cos(phi) * sin((ring + 1) / float(rings) * PI),
					cos((ring + 1) / float(rings) * PI),
					sin(phi) * sin((ring + 1) / float(rings) * PI)
				) * radius)
				st.add_vertex(center + Vector3(
					cos((segment + 1) / float(segments) * TAU) * sin((ring + 1) / float(rings) * PI),
					cos((ring + 1) / float(rings) * PI),
					sin((segment + 1) / float(segments) * TAU) * sin((ring + 1) / float(rings) * PI)
				) * radius)

## Alternative: Generate simple icosphere (lower poly, better distribution)
func generate_bullet_mesh_icosphere() -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var radius := 0.075
	_add_icosphere(surface_tool, Vector3.ZERO, radius, 1)  # 1 subdivision = 80 tris
	
	surface_tool.generate_normals()
	var mesh = surface_tool.commit()
	
	var material = _create_unlit_material(BULLET_WHITE)
	mesh.surface_set_material(0, material)
	
	return mesh

## Add icosphere (geodesic sphere - better low-poly distribution)
func _add_icosphere(st: SurfaceTool, center: Vector3, radius: float, subdivisions: int) -> void:
	# Start with icosahedron (20 faces, 12 vertices)
	var t := (1.0 + sqrt(5.0)) / 2.0  # Golden ratio
	
	# 12 vertices of icosahedron
	var vertices := [
		Vector3(-1, t, 0).normalized() * radius,
		Vector3(1, t, 0).normalized() * radius,
		Vector3(-1, -t, 0).normalized() * radius,
		Vector3(1, -t, 0).normalized() * radius,
		Vector3(0, -1, t).normalized() * radius,
		Vector3(0, 1, t).normalized() * radius,
		Vector3(0, -1, -t).normalized() * radius,
		Vector3(0, 1, -t).normalized() * radius,
		Vector3(t, 0, -1).normalized() * radius,
		Vector3(t, 0, 1).normalized() * radius,
		Vector3(-t, 0, -1).normalized() * radius,
		Vector3(-t, 0, 1).normalized() * radius,
	]
	
	# 20 faces (triangles) of icosahedron
	var faces := [
		[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
		[1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
		[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1],
	]
	
	# Add triangles (no subdivision for now to keep poly count low)
	for face in faces:
		var v1: Vector3 = center + vertices[face[0]]
		var v2: Vector3 = center + vertices[face[1]]
		var v3: Vector3 = center + vertices[face[2]]
		
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
