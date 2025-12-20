extends GutTest

## BDD Tests for TerrainCell
## Test-first approach: Write behavior tests before implementation

const TerrainCell = preload("res://src/domain/entities/terrain_cell.gd")
const Position = preload("res://src/domain/value_objects/position.gd")

## Test: Terrain Cell Creation
func test_given_terrain_parameters_when_created_then_has_correct_properties():
	# Given: Terrain cell creation parameters
	var position = Position.create(10, 10)
	var cell_type = TerrainCell.CellType.BRICK
	
	# When: Terrain cell is created
	var cell = TerrainCell.create(position, cell_type)
	
	# Then: Cell has correct properties
	assert_not_null(cell, "Cell should be created")
	assert_true(cell.position.equals(position), "Cell should have correct position")
	assert_eq(cell.cell_type, cell_type, "Cell should have correct type")
	assert_false(cell.is_destroyed, "Cell should not be destroyed initially")

## Test: Empty Terrain
func test_given_empty_cell_when_checked_then_is_passable_for_all():
	# Given: An empty terrain cell
	var cell = TerrainCell.create(Position.create(5, 5), TerrainCell.CellType.EMPTY)
	
	# When/Then: Checking passability
	assert_true(cell.is_passable_for_tank(), "Empty cell should be passable for tanks")
	assert_true(cell.is_passable_for_bullet(), "Empty cell should be passable for bullets")
	assert_false(cell.blocks_vision(), "Empty cell should not block vision")
	assert_false(cell.is_destructible(), "Empty cell should not be destructible")

## Test: Brick Terrain
func test_given_brick_cell_when_checked_then_has_correct_properties():
	# Given: A brick terrain cell
	var cell = TerrainCell.create(Position.create(5, 5), TerrainCell.CellType.BRICK)
	
	# When/Then: Checking properties
	assert_false(cell.is_passable_for_tank(), "Brick should not be passable for tanks")
	assert_false(cell.is_passable_for_bullet(), "Brick should not be passable for bullets")
	assert_true(cell.blocks_vision(), "Brick should block vision")
	assert_true(cell.is_destructible(), "Brick should be destructible")
	assert_eq(cell.health, 1, "Brick should have 1 health")

func test_given_brick_cell_when_takes_damage_then_is_destroyed():
	# Given: A brick terrain cell
	var cell = TerrainCell.create(Position.create(5, 5), TerrainCell.CellType.BRICK)
	
	# When: Cell takes damage
	cell.take_damage(1)
	
	# Then: Cell is destroyed
	assert_true(cell.is_destroyed, "Brick should be destroyed after taking damage")
	assert_eq(cell.health, 0, "Brick health should be zero")

## Test: Steel Terrain
func test_given_steel_cell_when_checked_then_is_indestructible():
	# Given: A steel terrain cell
	var cell = TerrainCell.create(Position.create(5, 5), TerrainCell.CellType.STEEL)
	
	# When/Then: Checking properties
	assert_false(cell.is_passable_for_tank(), "Steel should not be passable for tanks")
	assert_false(cell.is_passable_for_bullet(), "Steel should not be passable for bullets")
	assert_true(cell.blocks_vision(), "Steel should block vision")
	assert_false(cell.is_destructible(), "Steel should not be destructible")
	assert_eq(cell.health, 0, "Steel should have 0 health (indestructible)")

func test_given_steel_cell_when_takes_damage_then_not_destroyed():
	# Given: A steel terrain cell
	var cell = TerrainCell.create(Position.create(5, 5), TerrainCell.CellType.STEEL)
	
	# When: Cell takes damage
	cell.take_damage(10)
	
	# Then: Cell is not destroyed
	assert_false(cell.is_destroyed, "Steel should not be destroyed")

## Test: Water Terrain
func test_given_water_cell_when_checked_then_blocks_tanks_not_bullets():
	# Given: A water terrain cell
	var cell = TerrainCell.create(Position.create(5, 5), TerrainCell.CellType.WATER)
	
	# When/Then: Checking properties
	assert_false(cell.is_passable_for_tank(), "Water should not be passable for tanks")
	assert_true(cell.is_passable_for_bullet(), "Water should be passable for bullets")
	assert_false(cell.blocks_vision(), "Water should not block vision")
	assert_false(cell.is_destructible(), "Water should not be destructible")

## Test: Forest Terrain
func test_given_forest_cell_when_checked_then_passable_but_blocks_vision():
	# Given: A forest terrain cell
	var cell = TerrainCell.create(Position.create(5, 5), TerrainCell.CellType.FOREST)
	
	# When/Then: Checking properties
	assert_true(cell.is_passable_for_tank(), "Forest should be passable for tanks")
	assert_true(cell.is_passable_for_bullet(), "Forest should be passable for bullets")
	assert_true(cell.blocks_vision(), "Forest should block vision")
	assert_false(cell.is_destructible(), "Forest should not be destructible")

## Test: Ice Terrain
func test_given_ice_cell_when_checked_then_is_passable_for_all():
	# Given: An ice terrain cell
	var cell = TerrainCell.create(Position.create(5, 5), TerrainCell.CellType.ICE)
	
	# When/Then: Checking properties
	assert_true(cell.is_passable_for_tank(), "Ice should be passable for tanks")
	assert_true(cell.is_passable_for_bullet(), "Ice should be passable for bullets")
	assert_false(cell.blocks_vision(), "Ice should not block vision")
	assert_false(cell.is_destructible(), "Ice should not be destructible")

## Test: Terrain Cell Serialization
func test_given_terrain_cell_when_serialized_then_can_deserialize():
	# Given: A terrain cell with specific state
	var cell = TerrainCell.create(Position.create(10, 15), TerrainCell.CellType.BRICK)
	cell.take_damage(1)
	
	# When: Cell is serialized and deserialized
	var dict = cell.to_dict()
	var restored_cell = TerrainCell.from_dict(dict)
	
	# Then: Restored cell has same state
	assert_true(restored_cell.position.equals(cell.position), "Position should match")
	assert_eq(restored_cell.cell_type, cell.cell_type, "Cell type should match")
	assert_eq(restored_cell.health, cell.health, "Health should match")
	assert_eq(restored_cell.is_destroyed, cell.is_destroyed, "Destroyed state should match")

## Test: Destructible Terrain Health
func test_given_brick_cell_when_created_then_has_health():
	# Given/When: Creating a brick cell
	var cell = TerrainCell.create(Position.create(5, 5), TerrainCell.CellType.BRICK)
	
	# Then: Cell has health
	assert_gt(cell.health, 0, "Brick should have health > 0")

func test_given_brick_cell_with_health_when_takes_damage_then_health_decreases():
	# Given: A brick cell with 1 health
	var cell = TerrainCell.create(Position.create(5, 5), TerrainCell.CellType.BRICK)
	var initial_health = cell.health
	assert_eq(initial_health, 1, "Brick should have 1 health initially")
	
	# When: Cell takes damage equal to health
	cell.take_damage(1)
	
	# Then: Health becomes zero and cell is destroyed
	assert_eq(cell.health, 0, "Health should be zero")
	assert_true(cell.is_destroyed, "Cell should be destroyed")

## Test: Different Terrain Types
func test_given_different_terrain_types_when_created_then_have_correct_passability():
	# Given/When: Creating different terrain types
	var empty = TerrainCell.create(Position.create(0, 0), TerrainCell.CellType.EMPTY)
	var brick = TerrainCell.create(Position.create(1, 0), TerrainCell.CellType.BRICK)
	var steel = TerrainCell.create(Position.create(2, 0), TerrainCell.CellType.STEEL)
	var water = TerrainCell.create(Position.create(3, 0), TerrainCell.CellType.WATER)
	var forest = TerrainCell.create(Position.create(4, 0), TerrainCell.CellType.FOREST)
	var ice = TerrainCell.create(Position.create(5, 0), TerrainCell.CellType.ICE)
	
	# Then: Tank passability is correct
	assert_true(empty.is_passable_for_tank(), "Empty should allow tanks")
	assert_false(brick.is_passable_for_tank(), "Brick should block tanks")
	assert_false(steel.is_passable_for_tank(), "Steel should block tanks")
	assert_false(water.is_passable_for_tank(), "Water should block tanks")
	assert_true(forest.is_passable_for_tank(), "Forest should allow tanks")
	assert_true(ice.is_passable_for_tank(), "Ice should allow tanks")
	
	# And: Bullet passability is correct
	assert_true(empty.is_passable_for_bullet(), "Empty should allow bullets")
	assert_false(brick.is_passable_for_bullet(), "Brick should block bullets")
	assert_false(steel.is_passable_for_bullet(), "Steel should block bullets")
	assert_true(water.is_passable_for_bullet(), "Water should allow bullets")
	assert_true(forest.is_passable_for_bullet(), "Forest should allow bullets")
	assert_true(ice.is_passable_for_bullet(), "Ice should allow bullets")
