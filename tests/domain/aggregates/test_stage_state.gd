extends GutTest

## BDD Tests for StageState Aggregate
## Test-first approach: Write behavior tests before implementation

const StageState = preload("res://src/domain/aggregates/stage_state.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const TerrainCell = preload("res://src/domain/entities/terrain_cell.gd")
const BaseEntity = preload("res://src/domain/entities/base_entity.gd")

## Test: StageState Creation
func test_given_stage_parameters_when_created_then_has_correct_properties():
	# Given: Stage creation parameters
	var stage_number = 1
	var width = 26
	var height = 26
	
	# When: StageState is created
	var stage = StageState.create(stage_number, width, height)
	
	# Then: Stage has correct properties
	assert_not_null(stage, "Stage should be created")
	assert_eq(stage.stage_number, stage_number, "Stage should have correct number")
	assert_eq(stage.grid_width, width, "Stage should have correct width")
	assert_eq(stage.grid_height, height, "Stage should have correct height")
	assert_eq(stage.enemies_remaining, 20, "Stage should start with 20 enemies remaining")
	assert_eq(stage.enemies_on_field, 0, "Stage should start with no enemies on field")
	assert_eq(stage.max_enemies_on_field, 4, "Stage should allow max 4 enemies on field")

## Test: Bounds Checking
func test_given_stage_when_position_within_bounds_then_returns_true():
	# Given: A stage with standard dimensions
	var stage = StageState.create(1, 26, 26)
	var valid_pos = Position.create(10, 15)
	
	# When: Checking if position is within bounds
	var is_within = stage.is_within_bounds(valid_pos)
	
	# Then: Position is valid
	assert_true(is_within, "Position (10, 15) should be within bounds of 26x26 grid")

func test_given_stage_when_position_at_edge_then_returns_true():
	# Given: A stage with standard dimensions
	var stage = StageState.create(1, 26, 26)
	var edge_pos = Position.create(25, 25)
	
	# When: Checking if position at edge is within bounds
	var is_within = stage.is_within_bounds(edge_pos)
	
	# Then: Position at edge is valid
	assert_true(is_within, "Position (25, 25) should be within bounds")

func test_given_stage_when_position_out_of_bounds_then_returns_false():
	# Given: A stage with standard dimensions
	var stage = StageState.create(1, 26, 26)
	
	# When: Checking positions outside bounds
	var out_left = stage.is_within_bounds(Position.create(-1, 5))
	var out_right = stage.is_within_bounds(Position.create(26, 5))
	var out_top = stage.is_within_bounds(Position.create(5, -1))
	var out_bottom = stage.is_within_bounds(Position.create(5, 26))
	
	# Then: All out-of-bounds positions return false
	assert_false(out_left, "Position (-1, 5) should be out of bounds")
	assert_false(out_right, "Position (26, 5) should be out of bounds")
	assert_false(out_top, "Position (5, -1) should be out of bounds")
	assert_false(out_bottom, "Position (5, 26) should be out of bounds")

## Test: Terrain Management
func test_given_stage_when_terrain_cell_added_then_can_retrieve_it():
	# Given: A stage and a terrain cell
	var stage = StageState.create(1, 26, 26)
	var pos = Position.create(5, 5)
	var cell = TerrainCell.create(pos, TerrainCell.CellType.BRICK)
	
	# When: Terrain cell is added
	stage.add_terrain_cell(cell)
	
	# Then: Cell can be retrieved
	var retrieved = stage.get_terrain_at(pos)
	assert_not_null(retrieved, "Terrain cell should be retrievable")
	assert_eq(retrieved.cell_type, TerrainCell.CellType.BRICK, "Retrieved cell should be correct type")
	assert_true(retrieved.position.equals(pos), "Retrieved cell should have correct position")

func test_given_stage_when_no_terrain_at_position_then_returns_null():
	# Given: A stage without terrain at a specific position
	var stage = StageState.create(1, 26, 26)
	var empty_pos = Position.create(10, 10)
	
	# When: Retrieving terrain at empty position
	var retrieved = stage.get_terrain_at(empty_pos)
	
	# Then: Returns null
	assert_null(retrieved, "Should return null when no terrain at position")

func test_given_stage_when_multiple_terrain_cells_added_then_all_retrievable():
	# Given: A stage and multiple terrain cells
	var stage = StageState.create(1, 26, 26)
	var pos1 = Position.create(3, 4)
	var pos2 = Position.create(10, 12)
	var cell1 = TerrainCell.create(pos1, TerrainCell.CellType.BRICK)
	var cell2 = TerrainCell.create(pos2, TerrainCell.CellType.STEEL)
	
	# When: Multiple cells are added
	stage.add_terrain_cell(cell1)
	stage.add_terrain_cell(cell2)
	
	# Then: All cells can be retrieved
	var retrieved1 = stage.get_terrain_at(pos1)
	var retrieved2 = stage.get_terrain_at(pos2)
	assert_not_null(retrieved1, "First cell should be retrievable")
	assert_not_null(retrieved2, "Second cell should be retrievable")
	assert_eq(retrieved1.cell_type, TerrainCell.CellType.BRICK, "First cell should be BRICK")
	assert_eq(retrieved2.cell_type, TerrainCell.CellType.STEEL, "Second cell should be STEEL")

## Test: Base Management
func test_given_stage_when_base_set_then_has_base():
	# Given: A stage
	var stage = StageState.create(1, 26, 26)
	var base_pos = Position.create(12, 24)
	
	# When: Base is set
	stage.set_base(base_pos)
	
	# Then: Stage has a base at the position
	assert_not_null(stage.base, "Stage should have a base")
	assert_true(stage.base.position.equals(base_pos), "Base should be at correct position")

## Test: Spawn Position Management
func test_given_stage_when_player_spawn_added_then_is_stored():
	# Given: A stage
	var stage = StageState.create(1, 26, 26)
	var spawn_pos = Position.create(8, 24)
	
	# When: Player spawn position is added
	stage.add_player_spawn(spawn_pos)
	
	# Then: Spawn position is stored
	assert_eq(stage.player_spawn_positions.size(), 1, "Should have 1 player spawn")
	assert_true(stage.player_spawn_positions[0].equals(spawn_pos), "Spawn should be at correct position")

func test_given_stage_when_enemy_spawn_added_then_is_stored():
	# Given: A stage
	var stage = StageState.create(1, 26, 26)
	var spawn_pos = Position.create(0, 0)
	
	# When: Enemy spawn position is added
	stage.add_enemy_spawn(spawn_pos)
	
	# Then: Spawn position is stored
	assert_eq(stage.enemy_spawn_positions.size(), 1, "Should have 1 enemy spawn")
	assert_true(stage.enemy_spawn_positions[0].equals(spawn_pos), "Spawn should be at correct position")

func test_given_stage_when_multiple_spawns_added_then_all_stored():
	# Given: A stage
	var stage = StageState.create(1, 26, 26)
	
	# When: Multiple spawn positions are added
	stage.add_player_spawn(Position.create(8, 24))
	stage.add_player_spawn(Position.create(16, 24))
	stage.add_enemy_spawn(Position.create(0, 0))
	stage.add_enemy_spawn(Position.create(12, 0))
	stage.add_enemy_spawn(Position.create(24, 0))
	
	# Then: All spawns are stored
	assert_eq(stage.player_spawn_positions.size(), 2, "Should have 2 player spawns")
	assert_eq(stage.enemy_spawn_positions.size(), 3, "Should have 3 enemy spawns")

## Test: Enemy Spawning Logic
func test_given_stage_with_no_enemies_when_can_spawn_enemy_then_returns_true():
	# Given: A fresh stage with no enemies spawned
	var stage = StageState.create(1, 26, 26)
	
	# When: Checking if can spawn enemy
	var can_spawn = stage.can_spawn_enemy()
	
	# Then: Can spawn enemy (has remaining enemies and field not full)
	assert_true(can_spawn, "Should be able to spawn enemy on fresh stage")

func test_given_stage_with_max_enemies_on_field_when_can_spawn_enemy_then_returns_false():
	# Given: A stage with max enemies on field
	var stage = StageState.create(1, 26, 26)
	stage.enemies_on_field = stage.max_enemies_on_field # 4 enemies
	
	# When: Checking if can spawn enemy
	var can_spawn = stage.can_spawn_enemy()
	
	# Then: Cannot spawn enemy (field is full)
	assert_false(can_spawn, "Should not spawn when field is at max capacity")

func test_given_stage_with_no_enemies_remaining_when_can_spawn_enemy_then_returns_false():
	# Given: A stage with all enemies spawned
	var stage = StageState.create(1, 26, 26)
	stage.enemies_remaining = 0
	stage.enemies_on_field = 2
	
	# When: Checking if can spawn enemy
	var can_spawn = stage.can_spawn_enemy()
	
	# Then: Cannot spawn enemy (no enemies remaining)
	assert_false(can_spawn, "Should not spawn when no enemies remaining")

func test_given_stage_with_room_and_enemies_when_can_spawn_enemy_then_returns_true():
	# Given: A stage with some enemies on field but room for more
	var stage = StageState.create(1, 26, 26)
	stage.enemies_remaining = 15
	stage.enemies_on_field = 2 # Less than max of 4
	
	# When: Checking if can spawn enemy
	var can_spawn = stage.can_spawn_enemy()
	
	# Then: Can spawn enemy
	assert_true(can_spawn, "Should be able to spawn when there's room and enemies remaining")

## Test: Stage Completion Logic
func test_given_stage_with_enemies_remaining_when_is_complete_then_returns_false():
	# Given: A stage with enemies still remaining
	var stage = StageState.create(1, 26, 26)
	stage.enemies_remaining = 5
	stage.enemies_on_field = 2
	
	# When: Checking if stage is complete
	var is_complete = stage.is_complete()
	
	# Then: Stage is not complete
	assert_false(is_complete, "Stage should not be complete with enemies remaining")

func test_given_stage_with_enemies_on_field_when_is_complete_then_returns_false():
	# Given: A stage with no enemies remaining but some on field
	var stage = StageState.create(1, 26, 26)
	stage.enemies_remaining = 0
	stage.enemies_on_field = 2
	
	# When: Checking if stage is complete
	var is_complete = stage.is_complete()
	
	# Then: Stage is not complete (enemies still on field)
	assert_false(is_complete, "Stage should not be complete with enemies on field")

func test_given_stage_with_all_enemies_defeated_when_is_complete_then_returns_true():
	# Given: A stage with all enemies defeated
	var stage = StageState.create(1, 26, 26)
	stage.enemies_remaining = 0
	stage.enemies_on_field = 0
	
	# When: Checking if stage is complete
	var is_complete = stage.is_complete()
	
	# Then: Stage is complete
	assert_true(is_complete, "Stage should be complete when all enemies defeated")

## Test: Stage Failure Logic
func test_given_stage_with_alive_base_when_is_failed_then_returns_false():
	# Given: A stage with alive base
	var stage = StageState.create(1, 26, 26)
	stage.set_base(Position.create(12, 24))
	
	# When: Checking if stage is failed
	var is_failed = stage.is_failed()
	
	# Then: Stage is not failed
	assert_false(is_failed, "Stage should not be failed with alive base")

func test_given_stage_with_destroyed_base_when_is_failed_then_returns_true():
	# Given: A stage with destroyed base
	var stage = StageState.create(1, 26, 26)
	stage.set_base(Position.create(12, 24))
	stage.base.take_damage(stage.base.health.current) # Destroy base
	
	# When: Checking if stage is failed
	var is_failed = stage.is_failed()
	
	# Then: Stage is failed
	assert_true(is_failed, "Stage should be failed when base is destroyed")

## Test: Serialization
func test_given_stage_when_serialized_then_can_deserialize():
	# Given: A stage with data
	var stage = StageState.create(1, 26, 26)
	stage.set_base(Position.create(12, 24))
	stage.add_player_spawn(Position.create(8, 24))
	stage.add_enemy_spawn(Position.create(0, 0))
	stage.add_terrain_cell(TerrainCell.create(Position.create(5, 5), TerrainCell.CellType.BRICK))
	stage.enemies_remaining = 15
	stage.enemies_on_field = 3
	
	# When: Serializing and deserializing
	var dict = stage.to_dict()
	var restored = StageState.from_dict(dict)
	
	# Then: Restored stage has same data
	assert_eq(restored.stage_number, stage.stage_number, "Stage number should match")
	assert_eq(restored.grid_width, stage.grid_width, "Grid width should match")
	assert_eq(restored.grid_height, stage.grid_height, "Grid height should match")
	assert_eq(restored.enemies_remaining, stage.enemies_remaining, "Enemies remaining should match")
	assert_eq(restored.enemies_on_field, stage.enemies_on_field, "Enemies on field should match")
	assert_eq(restored.player_spawn_positions.size(), stage.player_spawn_positions.size(), "Player spawns count should match")
	assert_eq(restored.enemy_spawn_positions.size(), stage.enemy_spawn_positions.size(), "Enemy spawns count should match")
	assert_not_null(restored.base, "Restored stage should have base")
