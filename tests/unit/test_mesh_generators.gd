## Unit tests for 3D mesh generators
## Tests mesh generation, triangle counts, and validity

extends GutTest

# Preload generator scripts
const TankMeshGenerator = preload("res://resources/meshes3d/tank_mesh_generator.gd")
const BaseMeshGenerator = preload("res://resources/meshes3d/base_mesh_generator.gd")
const BulletMeshGenerator = preload("res://resources/meshes3d/bullet_mesh_generator.gd")
const TerrainMeshGenerator = preload("res://resources/meshes3d/terrain_mesh_generator.gd")

# Generators to test
var tank_gen
var base_gen
var bullet_gen
var terrain_gen

func before_each():
	tank_gen = TankMeshGenerator.new()
	base_gen = BaseMeshGenerator.new()
	bullet_gen = BulletMeshGenerator.new()
	terrain_gen = TerrainMeshGenerator.new()

func after_each():
	tank_gen = null
	base_gen = null
	bullet_gen = null
	terrain_gen = null

# ============================================
# Tank Mesh Tests
# ============================================

func test_player_tank_generates_valid_mesh():
	var mesh = tank_gen.generate_player_tank()
	
	assert_not_null(mesh, "Player tank mesh should not be null")
	assert_true(mesh is ArrayMesh, "Should return ArrayMesh")
	assert_gt(mesh.get_surface_count(), 0, "Mesh should have at least one surface")

func test_player_tank_within_triangle_budget():
	var mesh = tank_gen.generate_player_tank()
	var tri_count = _count_triangles(mesh)
	
	assert_gt(tri_count, 0, "Should have some triangles")
	assert_lte(tri_count, 600, "Player tank should be <= 600 tris (target ~500)")
	print("Player tank triangle count: ", tri_count)

func test_player_tank_has_material():
	var mesh = tank_gen.generate_player_tank()
	var material = mesh.surface_get_material(0)
	
	assert_not_null(material, "Mesh should have material assigned")
	assert_true(material is StandardMaterial3D, "Should be StandardMaterial3D")

func test_player_tank_has_reasonable_bounds():
	var mesh = tank_gen.generate_player_tank()
	var aabb = _get_mesh_aabb(mesh)
	
	assert_not_null(aabb, "Should have bounding box")
	# Player tank should be roughly 0.8 x 0.6 x 0.9 units
	assert_gt(aabb.size.x, 0.5, "Width should be > 0.5")
	assert_lt(aabb.size.x, 1.5, "Width should be < 1.5")
	assert_gt(aabb.size.y, 0.3, "Height should be > 0.3")
	assert_lt(aabb.size.y, 1.2, "Height should be < 1.2")

func test_enemy_tank_basic_generates():
	var mesh = tank_gen.generate_enemy_tank(TankMeshGenerator.EnemyType.BASIC)
	
	assert_not_null(mesh, "Enemy tank mesh should not be null")
	assert_gt(mesh.get_surface_count(), 0, "Should have surfaces")

func test_enemy_tank_within_budget():
	for type in [1, 2, 3, 4]:
		var mesh = tank_gen.generate_enemy_tank(type)
		var tri_count = _count_triangles(mesh)
		
		assert_lte(tri_count, 400, "Enemy tank type %d should be <= 400 tris" % type)
		print("Enemy tank type %d: %d tris" % [type, tri_count])

func test_all_enemy_types_generate():
	for type in [1, 2, 3, 4]:
		var mesh = tank_gen.generate_enemy_tank(type)
		assert_not_null(mesh, "Enemy type %d should generate" % type)
		assert_gt(mesh.get_surface_count(), 0, "Enemy type %d should have surfaces" % type)

# ============================================
# Base Mesh Tests
# ============================================

func test_base_mesh_generates():
	var mesh = base_gen.generate_base_mesh()
	
	assert_not_null(mesh, "Base mesh should not be null")
	assert_true(mesh is ArrayMesh, "Should return ArrayMesh")
	assert_gt(mesh.get_surface_count(), 0, "Should have surfaces")

func test_base_mesh_within_budget():
	var mesh = base_gen.generate_base_mesh()
	var tri_count = _count_triangles(mesh)
	
	assert_gt(tri_count, 0, "Should have triangles")
	assert_lte(tri_count, 400, "Base should be <= 400 tris (target ~300)")
	print("Base/Eagle triangle count: ", tri_count)

func test_base_mesh_has_material():
	var mesh = base_gen.generate_base_mesh()
	var material = mesh.surface_get_material(0)
	
	assert_not_null(material, "Base mesh should have material")

func test_base_mesh_reasonable_size():
	var mesh = base_gen.generate_base_mesh()
	var aabb = _get_mesh_aabb(mesh)
	
	# Base should be roughly 1.8 x 1.2 x 1.8 units
	assert_gt(aabb.size.x, 1.5, "Base width should be > 1.5")
	assert_lt(aabb.size.x, 2.5, "Base width should be < 2.5")
	assert_gt(aabb.size.y, 0.8, "Base height should be > 0.8")

# ============================================
# Bullet Mesh Tests
# ============================================

func test_bullet_mesh_generates():
	var mesh = bullet_gen.generate_bullet_mesh()
	
	assert_not_null(mesh, "Bullet mesh should not be null")
	assert_gt(mesh.get_surface_count(), 0, "Should have surfaces")

func test_bullet_mesh_within_budget():
	var mesh = bullet_gen.generate_bullet_mesh()
	var tri_count = _count_triangles(mesh)
	
	assert_gt(tri_count, 0, "Should have triangles")
	assert_lte(tri_count, 150, "Bullet should be <= 150 tris (target ~50)")
	print("Bullet (sphere) triangle count: ", tri_count)

func test_bullet_icosphere_generates():
	var mesh = bullet_gen.generate_bullet_mesh_icosphere()
	
	assert_not_null(mesh, "Icosphere bullet should generate")
	assert_gt(mesh.get_surface_count(), 0, "Should have surfaces")

func test_bullet_icosphere_within_budget():
	var mesh = bullet_gen.generate_bullet_mesh_icosphere()
	var tri_count = _count_triangles(mesh)
	
	assert_lte(tri_count, 100, "Icosphere bullet should be <= 100 tris")
	print("Bullet (icosphere) triangle count: ", tri_count)

func test_bullet_mesh_small_size():
	var mesh = bullet_gen.generate_bullet_mesh()
	var aabb = _get_mesh_aabb(mesh)
	
	# Bullet should be ~0.15 units diameter
	assert_lt(aabb.size.x, 0.3, "Bullet should be small (< 0.3 units)")
	assert_lt(aabb.size.y, 0.3, "Bullet should be small (< 0.3 units)")

# ============================================
# Terrain Mesh Tests
# ============================================

func test_brick_tile_generates():
	var mesh = terrain_gen.generate_brick_tile()
	
	assert_not_null(mesh, "Brick tile should generate")
	assert_gt(mesh.get_surface_count(), 0, "Should have surfaces")

func test_brick_tile_low_poly():
	var mesh = terrain_gen.generate_brick_tile()
	var tri_count = _count_triangles(mesh)
	
	assert_lte(tri_count, 20, "Brick tile should be <= 20 tris (target 12)")
	print("Brick tile triangle count: ", tri_count)

func test_steel_tile_generates():
	var mesh = terrain_gen.generate_steel_tile()
	
	assert_not_null(mesh, "Steel tile should generate")

func test_steel_tile_low_poly():
	var mesh = terrain_gen.generate_steel_tile()
	var tri_count = _count_triangles(mesh)
	
	assert_lte(tri_count, 20, "Steel tile should be <= 20 tris")
	print("Steel tile triangle count: ", tri_count)

func test_water_tile_generates():
	var mesh = terrain_gen.generate_water_tile()
	
	assert_not_null(mesh, "Water tile should generate")

func test_water_tile_low_poly():
	var mesh = terrain_gen.generate_water_tile()
	var tri_count = _count_triangles(mesh)
	
	assert_lte(tri_count, 20, "Water tile should be <= 20 tris")
	print("Water tile triangle count: ", tri_count)

func test_forest_tile_generates():
	var mesh = terrain_gen.generate_forest_tile()
	
	assert_not_null(mesh, "Forest tile should generate")

func test_forest_tile_within_budget():
	var mesh = terrain_gen.generate_forest_tile()
	var tri_count = _count_triangles(mesh)
	
	assert_lte(tri_count, 150, "Forest tile should be <= 150 tris (target ~100)")
	print("Forest tile triangle count: ", tri_count)

func test_terrain_tiles_have_materials():
	var brick = terrain_gen.generate_brick_tile()
	var steel = terrain_gen.generate_steel_tile()
	var water = terrain_gen.generate_water_tile()
	var forest = terrain_gen.generate_forest_tile()
	
	assert_not_null(brick.surface_get_material(0), "Brick should have material")
	assert_not_null(steel.surface_get_material(0), "Steel should have material")
	assert_not_null(water.surface_get_material(0), "Water should have material")
	assert_not_null(forest.surface_get_material(0), "Forest should have material")

func test_terrain_tiles_proper_size():
	var brick = terrain_gen.generate_brick_tile()
	var aabb = _get_mesh_aabb(brick)
	
	# Tiles should be ~1x1 units footprint
	assert_gt(aabb.size.x, 0.8, "Tile width should be close to 1 unit")
	assert_lt(aabb.size.x, 1.2, "Tile width should be close to 1 unit")

# ============================================
# Performance Budget Tests
# ============================================

func test_total_scene_budget():
	# Simulate typical scene: 1 player, 8 enemies, 1 base, 10 bullets, 100 terrain tiles
	var player_tris = _count_triangles(tank_gen.generate_player_tank())
	var enemy_tris = _count_triangles(tank_gen.generate_enemy_tank(1)) * 8
	var base_tris = _count_triangles(base_gen.generate_base_mesh())
	var bullet_tris = _count_triangles(bullet_gen.generate_bullet_mesh()) * 10
	var terrain_tris = _count_triangles(terrain_gen.generate_brick_tile()) * 100
	
	var total = player_tris + enemy_tris + base_tris + bullet_tris + terrain_tris
	
	print("Scene budget breakdown:")
	print("  Player: %d tris" % player_tris)
	print("  Enemies (8x): %d tris" % enemy_tris)
	print("  Base: %d tris" % base_tris)
	print("  Bullets (10x): %d tris" % bullet_tris)
	print("  Terrain (100x): %d tris" % terrain_tris)
	print("  TOTAL: %d tris" % total)
	
	assert_lte(total, 25000, "Total scene should be <= 25k tris for performance")

# ============================================
# Helper Functions
# ============================================

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

func _get_mesh_aabb(mesh: ArrayMesh) -> AABB:
	if mesh.get_surface_count() == 0:
		return AABB()
	
	var arrays = mesh.surface_get_arrays(0)
	if arrays.is_empty():
		return AABB()
	
	var vertices = arrays[Mesh.ARRAY_VERTEX]
	if vertices == null or vertices.size() == 0:
		return AABB()
	
	var min_point: Vector3 = vertices[0]
	var max_point: Vector3 = vertices[0]
	
	for v in vertices:
		min_point.x = min(min_point.x, v.x)
		min_point.y = min(min_point.y, v.y)
		min_point.z = min(min_point.z, v.z)
		max_point.x = max(max_point.x, v.x)
		max_point.y = max(max_point.y, v.y)
		max_point.z = max(max_point.z, v.z)
	
	return AABB(min_point, max_point - min_point)
