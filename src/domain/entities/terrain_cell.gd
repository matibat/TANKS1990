class_name TerrainCell
extends RefCounted

## TerrainCell - Domain Entity
## Represents a single cell in the game terrain grid
## Part of DDD architecture - pure domain logic with no Godot dependencies

const Position = preload("res://src/domain/value_objects/position.gd")

## Terrain cell type enum
enum CellType {
	EMPTY = 0,
	BRICK = 1,
	STEEL = 2,
	WATER = 3,
	FOREST = 4,
	ICE = 5
}

## Properties
var position: Position
var cell_type: int
var health: int
var is_destroyed: bool

## Static factory method to create a terrain cell
static func create(p_position: Position, p_cell_type: int):
	var cell = new()
	cell.position = p_position
	cell.cell_type = p_cell_type
	cell.is_destroyed = false
	
	# Set health based on cell type
	match p_cell_type:
		CellType.BRICK:
			cell.health = 1 # Destructible with 1 hit
		CellType.STEEL:
			cell.health = 0 # Indestructible (0 = infinite)
		_:
			cell.health = 0 # Non-destructible types
	
	return cell

## Check if cell is passable for tanks
func is_passable_for_tank() -> bool:
	match cell_type:
		CellType.EMPTY, CellType.FOREST, CellType.ICE:
			return true
		CellType.BRICK, CellType.STEEL, CellType.WATER:
			return false if not is_destroyed else true
		_:
			return true

## Check if cell is passable for bullets
func is_passable_for_bullet() -> bool:
	match cell_type:
		CellType.EMPTY, CellType.WATER, CellType.FOREST, CellType.ICE:
			return true
		CellType.BRICK, CellType.STEEL:
			return false if not is_destroyed else true
		_:
			return true

## Check if cell blocks vision
func blocks_vision() -> bool:
	match cell_type:
		CellType.BRICK, CellType.STEEL, CellType.FOREST:
			return not is_destroyed
		_:
			return false

## Check if cell is destructible
func is_destructible() -> bool:
	return cell_type == CellType.BRICK

## Take damage (only affects destructible cells)
func take_damage(amount: int) -> void:
	if not is_destructible():
		return
	
	health = max(0, health - amount)
	if health == 0:
		is_destroyed = true

## Serialize to dictionary
func to_dict() -> Dictionary:
	return {
		"position": position.to_dict(),
		"cell_type": cell_type,
		"health": health,
		"is_destroyed": is_destroyed
	}

## Deserialize from dictionary
static func from_dict(dict: Dictionary):
	var cell = new()
	cell.position = Position.from_dict(dict["position"])
	cell.cell_type = dict["cell_type"]
	cell.health = dict["health"]
	cell.is_destroyed = dict["is_destroyed"]
	return cell

## String representation for debugging
func _to_string() -> String:
	var type_name = ""
	match cell_type:
		CellType.EMPTY: type_name = "EMPTY"
		CellType.BRICK: type_name = "BRICK"
		CellType.STEEL: type_name = "STEEL"
		CellType.WATER: type_name = "WATER"
		CellType.FOREST: type_name = "FOREST"
		CellType.ICE: type_name = "ICE"
		_: type_name = "UNKNOWN"
	
	return "TerrainCell(pos:%s, type:%s, hp:%d, destroyed:%s)" % [
		position, type_name, health, is_destroyed
	]
