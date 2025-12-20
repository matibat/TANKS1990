class_name StageState
extends RefCounted

## StageState Aggregate
## Represents one game stage/level with terrain, spawns, and enemy tracking
## Part of DDD architecture - pure domain logic with no Godot dependencies

const Position = preload("res://src/domain/value_objects/position.gd")
const TerrainCell = preload("res://src/domain/entities/terrain_cell.gd")
const BaseEntity = preload("res://src/domain/entities/base_entity.gd")

## Properties
var stage_number: int
var grid_width: int
var grid_height: int
var terrain: Dictionary # Position key -> TerrainCell
var base: BaseEntity
var player_spawn_positions: Array # Array of Position
var enemy_spawn_positions: Array # Array of Position
var enemies_remaining: int
var enemies_on_field: int
var max_enemies_on_field: int

## Static factory method to create a stage
static func create(p_stage_number: int, p_width: int, p_height: int):
	var stage = new()
	stage.stage_number = p_stage_number
	stage.grid_width = p_width
	stage.grid_height = p_height
	stage.terrain = {}
	stage.base = null
	stage.player_spawn_positions = []
	stage.enemy_spawn_positions = []
	stage.enemies_remaining = 20 # Standard: 20 enemies per stage
	stage.enemies_on_field = 0
	stage.max_enemies_on_field = 4 # Max 4 enemies on field at once
	return stage

## Check if position is within stage bounds
func is_within_bounds(pos: Position) -> bool:
	return pos.x >= 0 and pos.x < grid_width and pos.y >= 0 and pos.y < grid_height

## Get terrain cell at position
func get_terrain_at(pos: Position):
	var key = _position_to_key(pos)
	if terrain.has(key):
		return terrain[key]
	return null

## Add terrain cell to stage
func add_terrain_cell(cell: TerrainCell) -> void:
	var key = _position_to_key(cell.position)
	terrain[key] = cell

## Set the base position
func set_base(base_pos: Position) -> void:
	base = BaseEntity.create("base", base_pos, 1)

## Add player spawn position
func add_player_spawn(pos: Position) -> void:
	player_spawn_positions.append(pos)

## Add enemy spawn position
func add_enemy_spawn(pos: Position) -> void:
	enemy_spawn_positions.append(pos)

## Check if can spawn enemy (has remaining enemies and field not full)
func can_spawn_enemy() -> bool:
	return enemies_remaining > 0 and enemies_on_field < max_enemies_on_field

## Check if stage is complete (all enemies defeated)
func is_complete() -> bool:
	return enemies_remaining == 0 and enemies_on_field == 0

## Check if stage is failed (base destroyed)
func is_failed() -> bool:
	if base == null:
		return false
	return not base.is_alive()

## Serialize to dictionary
func to_dict() -> Dictionary:
	var terrain_array = []
	for key in terrain:
		terrain_array.append(terrain[key].to_dict())
	
	var player_spawns_array = []
	for spawn in player_spawn_positions:
		player_spawns_array.append(spawn.to_dict())
	
	var enemy_spawns_array = []
	for spawn in enemy_spawn_positions:
		enemy_spawns_array.append(spawn.to_dict())
	
	return {
		"stage_number": stage_number,
		"grid_width": grid_width,
		"grid_height": grid_height,
		"terrain": terrain_array,
		"base": base.to_dict() if base != null else null,
		"player_spawn_positions": player_spawns_array,
		"enemy_spawn_positions": enemy_spawns_array,
		"enemies_remaining": enemies_remaining,
		"enemies_on_field": enemies_on_field,
		"max_enemies_on_field": max_enemies_on_field
	}

## Deserialize from dictionary
static func from_dict(dict: Dictionary):
	var stage = new()
	stage.stage_number = dict["stage_number"]
	stage.grid_width = dict["grid_width"]
	stage.grid_height = dict["grid_height"]
	stage.enemies_remaining = dict["enemies_remaining"]
	stage.enemies_on_field = dict["enemies_on_field"]
	stage.max_enemies_on_field = dict["max_enemies_on_field"]
	
	# Restore terrain
	stage.terrain = {}
	for terrain_data in dict["terrain"]:
		var cell = TerrainCell.from_dict(terrain_data)
		stage.add_terrain_cell(cell)
	
	# Restore base
	if dict["base"] != null:
		stage.base = BaseEntity.from_dict(dict["base"])
	else:
		stage.base = null
	
	# Restore player spawn positions
	stage.player_spawn_positions = []
	for spawn_data in dict["player_spawn_positions"]:
		stage.player_spawn_positions.append(Position.from_dict(spawn_data))
	
	# Restore enemy spawn positions
	stage.enemy_spawn_positions = []
	for spawn_data in dict["enemy_spawn_positions"]:
		stage.enemy_spawn_positions.append(Position.from_dict(spawn_data))
	
	return stage

## Private: Convert position to dictionary key
func _position_to_key(pos: Position) -> String:
	return "%d,%d" % [pos.x, pos.y]
