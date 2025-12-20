extends Node3D

# Asset Gallery - displays all 3D meshes for verification
# Rotates meshes and displays triangle counts

var meshes_loaded := 0
var total_triangles := 0

func _ready():
	print("=== Asset Gallery Loaded ===")
	_count_meshes()
	print("Total meshes loaded: ", meshes_loaded)
	print("Total triangles: ", total_triangles)

func _process(delta):
	# Rotate all mesh instances slowly
	for child in get_children():
		if child is MeshInstance3D:
			child.rotate_y(delta * 0.5)

func _count_meshes():
	_count_meshes_recursive(self)

func _count_meshes_recursive(node: Node):
	if node is MeshInstance3D:
		meshes_loaded += 1
		var tri_count = _count_triangles(node)
		total_triangles += tri_count
		print("  %s: %d triangles" % [node.name, tri_count])
	
	for child in node.get_children():
		_count_meshes_recursive(child)

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
