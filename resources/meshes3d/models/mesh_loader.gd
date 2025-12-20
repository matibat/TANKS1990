@tool
extends MeshInstance3D

## Generic mesh loader that uses procedural generators
## Set mesh_type and generator_class in scene

# Preload generator classes
const TankMeshGenerator = preload("res://resources/meshes3d/tank_mesh_generator.gd")
const BulletMeshGenerator = preload("res://resources/meshes3d/bullet_mesh_generator.gd")
const TerrainMeshGenerator = preload("res://resources/meshes3d/terrain_mesh_generator.gd")
const BaseMeshGenerator = preload("res://resources/meshes3d/base_mesh_generator.gd")

@export var mesh_type: String = ""
@export var generator_class: String = ""
@export var material_path: String = ""

func _ready():
	if generator_class.is_empty():
		push_warning("MeshLoader: generator_class not set")
		return
	
	# Check if mesh_type is required for this generator
	var requires_mesh_type := generator_class in ["TankMeshGenerator", "TerrainMeshGenerator"]
	if requires_mesh_type and mesh_type.is_empty():
		push_warning("MeshLoader: mesh_type not set for " + generator_class)
		return
	
	# Load generator
	var generator
	match generator_class:
		"TankMeshGenerator":
			generator = TankMeshGenerator.new()
		"BulletMeshGenerator":
			generator = BulletMeshGenerator.new()
		"TerrainMeshGenerator":
			generator = TerrainMeshGenerator.new()
		"BaseMeshGenerator":
			generator = BaseMeshGenerator.new()
		_:
			push_error("Unknown generator class: " + generator_class)
			return
	
	# Generate mesh based on type
	match generator_class:
		"TankMeshGenerator":
			mesh = _generate_tank_mesh(generator, mesh_type)
		"BulletMeshGenerator":
			mesh = generator.generate_bullet_mesh()
		"TerrainMeshGenerator":
			mesh = _generate_terrain_mesh(generator, mesh_type)
		"BaseMeshGenerator":
			mesh = generator.generate_base_mesh()
	
	# Apply material
	if not material_path.is_empty() and ResourceLoader.exists(material_path):
		var mat = load(material_path)
		set_surface_override_material(0, mat)

func _generate_tank_mesh(generator, type: String) -> ArrayMesh:
	match type:
		"player":
			return generator.generate_player_tank()
		"enemy_basic":
			return generator.generate_enemy_tank(TankMeshGenerator.EnemyType.BASIC)
		"enemy_fast":
			return generator.generate_enemy_tank(TankMeshGenerator.EnemyType.FAST)
		"enemy_heavy":
			return generator.generate_enemy_tank(TankMeshGenerator.EnemyType.HEAVY)
		"enemy_light":
			return generator.generate_enemy_tank(TankMeshGenerator.EnemyType.LIGHT)
		_:
			push_error("Unknown tank type: " + type)
			return generator.generate_player_tank()

func _generate_terrain_mesh(generator, type: String) -> ArrayMesh:
	match type:
		"brick":
			return generator.generate_tile(TerrainMeshGenerator.TileType.BRICK)
		"steel":
			return generator.generate_tile(TerrainMeshGenerator.TileType.STEEL)
		"water":
			return generator.generate_tile(TerrainMeshGenerator.TileType.WATER)
		"forest":
			return generator.generate_tile(TerrainMeshGenerator.TileType.FOREST)
		_:
			push_error("Unknown terrain type: " + type)
			return generator.generate_tile(TerrainMeshGenerator.TileType.BRICK)
