@tool
extends EditorScript

# This script generates all 3D model scenes for the TANKS1990 project
# Run this from the Godot editor: File -> Run

const MODELS_DIR = "res://resources/meshes3d/models/"
const MATERIALS_DIR = "res://resources/materials/"

func _run():
	print("=== Generating all 3D model scenes ===")
	
	# Load mesh generators
	var tank_gen = TankMeshGenerator.new()
	var bullet_gen = BulletMeshGenerator.new()
	var terrain_gen = TerrainMeshGenerator.new()
	var base_gen = BaseMeshGenerator.new()
	
	# Generate player tank meshes
	_generate_player_tanks(tank_gen)
	
	# Generate enemy tank meshes
	_generate_enemy_tanks(tank_gen)
	
	# Generate bullet mesh
	_generate_bullet(bullet_gen)
	
	# Generate base/eagle mesh
	_generate_base(base_gen)
	
	# Generate terrain tile meshes
	_generate_terrain_tiles(terrain_gen)
	
	# Generate power-up meshes
	_generate_powerups()
	
	print("=== Model generation complete! ===")

func _generate_player_tanks(tank_gen: TankMeshGenerator):
	print("Generating player tank meshes...")
	
	var levels = [
		{"name": "tank_base", "level": 0},
		{"name": "tank_level1", "level": 1},
		{"name": "tank_level2", "level": 2},
		{"name": "tank_level3", "level": 3}
	]
	
	for level_data in levels:
		var mesh = tank_gen.generate_player_tank()
		var scene = _create_mesh_scene(mesh, "mat_tank_yellow.tres")
		var path = MODELS_DIR + level_data.name + ".tscn"
		var packed_scene = PackedScene.new()
		packed_scene.pack(scene)
		ResourceSaver.save(packed_scene, path)
		print("  Created: ", path)

func _generate_enemy_tanks(tank_gen: TankMeshGenerator):
	print("Generating enemy tank meshes...")
	
	var enemies = [
		{"name": "enemy_basic", "type": TankMeshGenerator.EnemyType.BASIC, "material": "mat_enemy_brown.tres"},
		{"name": "enemy_fast", "type": TankMeshGenerator.EnemyType.FAST, "material": "mat_enemy_gray.tres"},
		{"name": "enemy_power", "type": TankMeshGenerator.EnemyType.HEAVY, "material": "mat_enemy_green.tres"},
		{"name": "enemy_armored", "type": TankMeshGenerator.EnemyType.BASIC, "material": "mat_enemy_red.tres"}
	]
	
	for enemy_data in enemies:
		var mesh = tank_gen.generate_enemy_tank(enemy_data.type)
		var scene = _create_mesh_scene(mesh, enemy_data.material)
		var path = MODELS_DIR + enemy_data.name + ".tscn"
		var packed_scene = PackedScene.new()
		packed_scene.pack(scene)
		ResourceSaver.save(packed_scene, path)
		print("  Created: ", path)

func _generate_bullet(bullet_gen: BulletMeshGenerator):
	print("Generating bullet mesh...")
	
	var mesh = bullet_gen.generate_bullet()
	var scene = _create_mesh_scene(mesh, "mat_bullet.tres")
	var path = MODELS_DIR + "bullet.tscn"
	var packed_scene = PackedScene.new()
	packed_scene.pack(scene)
	ResourceSaver.save(packed_scene, path)
	print("  Created: ", path)

func _generate_base(base_gen: BaseMeshGenerator):
	print("Generating base/eagle mesh...")
	
	var mesh = base_gen.generate_base()
	var scene = _create_mesh_scene(mesh, "mat_base_eagle.tres")
	var path = MODELS_DIR + "base_eagle.tscn"
	var packed_scene = PackedScene.new()
	packed_scene.pack(scene)
	ResourceSaver.save(packed_scene, path)
	print("  Created: ", path)

func _generate_terrain_tiles(terrain_gen: TerrainMeshGenerator):
	print("Generating terrain tile meshes...")
	
	var tiles = [
		{"name": "tile_brick", "type": TerrainMeshGenerator.TileType.BRICK, "material": "mat_brick.tres"},
		{"name": "tile_steel", "type": TerrainMeshGenerator.TileType.STEEL, "material": "mat_steel.tres"},
		{"name": "tile_water", "type": TerrainMeshGenerator.TileType.WATER, "material": "mat_water.tres"},
		{"name": "tile_forest", "type": TerrainMeshGenerator.TileType.FOREST, "material": "mat_forest.tres"}
	]
	
	for tile_data in tiles:
		var mesh = terrain_gen.generate_tile(tile_data.type)
		var scene = _create_mesh_scene(mesh, tile_data.material)
		var path = MODELS_DIR + tile_data.name + ".tscn"
		var packed_scene = PackedScene.new()
		packed_scene.pack(scene)
		ResourceSaver.save(packed_scene, path)
		print("  Created: ", path)

func _generate_powerups():
	print("Generating power-up meshes...")
	
	var powerups = [
		{"name": "powerup_tank", "shape": "miniature_tank", "material": "mat_powerup_tank.tres"},
		{"name": "powerup_star", "shape": "star", "material": "mat_powerup_star.tres"},
		{"name": "powerup_grenade", "shape": "sphere", "material": "mat_powerup_grenade.tres"},
		{"name": "powerup_shield", "shape": "shield", "material": "mat_powerup_shield.tres"},
		{"name": "powerup_timer", "shape": "cylinder", "material": "mat_powerup_timer.tres"},
		{"name": "powerup_shovel", "shape": "box", "material": "mat_powerup_shovel.tres"}
	]
	
	for powerup_data in powerups:
		var mesh = _generate_powerup_mesh(powerup_data.shape)
		var scene = _create_mesh_scene(mesh, powerup_data.material)
		var path = MODELS_DIR + powerup_data.name + ".tscn"
		var packed_scene = PackedScene.new()
		packed_scene.pack(scene)
		ResourceSaver.save(packed_scene, path)
		print("  Created: ", path)

func _generate_powerup_mesh(shape: String) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	match shape:
		"star":
			_add_star(st, 0.3, 0.15, 5)
		"sphere":
			_add_sphere(st, 0.15, 8, 8)
		"shield":
			_add_shield(st, 0.25, 0.3)
		"miniature_tank":
			_add_mini_tank(st)
		"cylinder":
			_add_cylinder(st, 0.15, 0.2, 12)
		"box":
			_add_box(st, Vector3(0.2, 0.3, 0.15))
	
	st.generate_normals()
	return st.commit()

func _add_star(st: SurfaceTool, outer_radius: float, inner_radius: float, points: int):
	# Generate 5-pointed star
	var angle_step = TAU / points
	var extrude = 0.1
	
	for i in range(points):
		var angle1 = i * angle_step
		var angle2 = (i + 0.5) * angle_step
		var angle3 = (i + 1) * angle_step
		
		var outer1 = Vector3(cos(angle1) * outer_radius, 0, sin(angle1) * outer_radius)
		var inner = Vector3(cos(angle2) * inner_radius, 0, sin(angle2) * inner_radius)
		var outer2 = Vector3(cos(angle3) * outer_radius, 0, sin(angle3) * outer_radius)
		
		# Front face triangle
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(outer1)
		st.add_vertex(inner)
		
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(inner)
		st.add_vertex(outer2)
		
		# Extrude sides
		_add_quad(st, outer1, inner, inner + Vector3(0, extrude, 0), outer1 + Vector3(0, extrude, 0))
		_add_quad(st, inner, outer2, outer2 + Vector3(0, extrude, 0), inner + Vector3(0, extrude, 0))

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
	# Shield shape with cross
	var points = [
		Vector3(-width, height, 0), Vector3(width, height, 0),
		Vector3(width, 0, 0), Vector3(width/2, -height/3, 0),
		Vector3(0, -height, 0), Vector3(-width/2, -height/3, 0),
		Vector3(-width, 0, 0)
	]
	
	# Front face
	for i in range(1, points.size() - 1):
		st.add_vertex(points[0])
		st.add_vertex(points[i])
		st.add_vertex(points[i + 1])
	
	# Extrude
	var extrude = 0.05
	for i in range(points.size()):
		var p1 = points[i]
		var p2 = points[(i + 1) % points.size()]
		_add_quad(st, p1, p2, p2 + Vector3(0, 0, extrude), p1 + Vector3(0, 0, extrude))

func _add_mini_tank(st: SurfaceTool):
	# Miniature tank body
	var size = Vector3(0.3, 0.15, 0.3)
	_add_box(st, size)

func _add_cylinder(st: SurfaceTool, radius: float, height: float, segments: int):
	for i in range(segments):
		var angle1 = i * TAU / segments
		var angle2 = (i + 1) * TAU / segments
		
		var p1 = Vector3(cos(angle1) * radius, 0, sin(angle1) * radius)
		var p2 = Vector3(cos(angle2) * radius, 0, sin(angle2) * radius)
		var p3 = p2 + Vector3(0, height, 0)
		var p4 = p1 + Vector3(0, height, 0)
		
		# Side quad
		_add_quad(st, p1, p2, p3, p4)
		
		# Top and bottom caps
		st.add_vertex(Vector3(0, 0, 0))
		st.add_vertex(p2)
		st.add_vertex(p1)
		
		st.add_vertex(Vector3(0, height, 0))
		st.add_vertex(p4)
		st.add_vertex(p3)

func _add_box(st: SurfaceTool, size: Vector3):
	var hs = size / 2.0
	
	# Front face
	st.add_vertex(Vector3(-hs.x, -hs.y, hs.z))
	st.add_vertex(Vector3(hs.x, -hs.y, hs.z))
	st.add_vertex(Vector3(hs.x, hs.y, hs.z))
	
	st.add_vertex(Vector3(-hs.x, -hs.y, hs.z))
	st.add_vertex(Vector3(hs.x, hs.y, hs.z))
	st.add_vertex(Vector3(-hs.x, hs.y, hs.z))
	
	# Back face
	st.add_vertex(Vector3(hs.x, -hs.y, -hs.z))
	st.add_vertex(Vector3(-hs.x, -hs.y, -hs.z))
	st.add_vertex(Vector3(-hs.x, hs.y, -hs.z))
	
	st.add_vertex(Vector3(hs.x, -hs.y, -hs.z))
	st.add_vertex(Vector3(-hs.x, hs.y, -hs.z))
	st.add_vertex(Vector3(hs.x, hs.y, -hs.z))
	
	# Top face
	st.add_vertex(Vector3(-hs.x, hs.y, hs.z))
	st.add_vertex(Vector3(hs.x, hs.y, hs.z))
	st.add_vertex(Vector3(hs.x, hs.y, -hs.z))
	
	st.add_vertex(Vector3(-hs.x, hs.y, hs.z))
	st.add_vertex(Vector3(hs.x, hs.y, -hs.z))
	st.add_vertex(Vector3(-hs.x, hs.y, -hs.z))
	
	# Bottom face
	st.add_vertex(Vector3(-hs.x, -hs.y, -hs.z))
	st.add_vertex(Vector3(hs.x, -hs.y, -hs.z))
	st.add_vertex(Vector3(hs.x, -hs.y, hs.z))
	
	st.add_vertex(Vector3(-hs.x, -hs.y, -hs.z))
	st.add_vertex(Vector3(hs.x, -hs.y, hs.z))
	st.add_vertex(Vector3(-hs.x, -hs.y, hs.z))
	
	# Left face
	st.add_vertex(Vector3(-hs.x, -hs.y, -hs.z))
	st.add_vertex(Vector3(-hs.x, -hs.y, hs.z))
	st.add_vertex(Vector3(-hs.x, hs.y, hs.z))
	
	st.add_vertex(Vector3(-hs.x, -hs.y, -hs.z))
	st.add_vertex(Vector3(-hs.x, hs.y, hs.z))
	st.add_vertex(Vector3(-hs.x, hs.y, -hs.z))
	
	# Right face
	st.add_vertex(Vector3(hs.x, -hs.y, hs.z))
	st.add_vertex(Vector3(hs.x, -hs.y, -hs.z))
	st.add_vertex(Vector3(hs.x, hs.y, -hs.z))
	
	st.add_vertex(Vector3(hs.x, -hs.y, hs.z))
	st.add_vertex(Vector3(hs.x, hs.y, -hs.z))
	st.add_vertex(Vector3(hs.x, hs.y, hs.z))

func _add_quad(st: SurfaceTool, v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3):
	st.add_vertex(v1)
	st.add_vertex(v2)
	st.add_vertex(v3)
	
	st.add_vertex(v1)
	st.add_vertex(v3)
	st.add_vertex(v4)

func _create_mesh_scene(mesh: ArrayMesh, material_name: String) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	
	# Load and apply material
	var material_path = MATERIALS_DIR + material_name
	if ResourceLoader.exists(material_path):
		var material = load(material_path)
		mesh_instance.set_surface_override_material(0, material)
	
	return mesh_instance
