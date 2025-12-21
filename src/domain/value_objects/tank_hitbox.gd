class_name TankHitbox
extends RefCounted

## TankHitbox Value Object
## Represents the collision hitbox for a tank (4 units wide × 3 units long)
## The 4th visual unit is NOT included in the hitbox
## Hitbox rotates based on tank's facing direction
## Part of DDD architecture - pure domain logic with no Godot dependencies

const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")

## Tank dimensions
const HITBOX_WIDTH = 4  # Units perpendicular to direction
const HITBOX_LENGTH = 3  # Units parallel to direction (NOT 4 - excludes visual nose)

var center_position: Position
var direction: Direction
var _occupied_tiles: Array = []

## Static factory method to create a tank hitbox
static func create(pos: Position, dir: Direction):
	var hitbox = new()
	hitbox.center_position = pos
	hitbox.direction = dir
	hitbox._occupied_tiles = hitbox._calculate_occupied_tiles()
	return hitbox

## Calculate all tiles occupied by this hitbox based on direction
func _calculate_occupied_tiles() -> Array:
	var tiles: Array = []
	
	match direction.value:
		Direction.UP:
			# Facing NORTH: 4 wide (X axis), 3 long forward (negative Y)
			# Center at (cx, cy), extends:
			# X: from (cx - 2) to (cx + 1) = 4 tiles wide
			# Y: from (cy - 2) to cy = 3 tiles long (forward is negative Y)
			for x_offset in range(-2, 2):  # -2, -1, 0, 1 = 4 tiles
				for y_offset in range(-2, 1):  # -2, -1, 0 = 3 tiles
					tiles.append(Position.create(
						center_position.x + x_offset,
						center_position.y + y_offset
					))
		
		Direction.DOWN:
			# Facing SOUTH: 4 wide (X axis), 3 long forward (positive Y)
			# X: from (cx - 2) to (cx + 1) = 4 tiles wide
			# Y: from cy to (cy + 2) = 3 tiles long (forward is positive Y)
			for x_offset in range(-2, 2):  # -2, -1, 0, 1 = 4 tiles
				for y_offset in range(0, 3):  # 0, 1, 2 = 3 tiles
					tiles.append(Position.create(
						center_position.x + x_offset,
						center_position.y + y_offset
					))
		
		Direction.LEFT:
			# Facing WEST: 4 wide (Y axis), 3 long forward (negative X)
			# X: from (cx - 2) to cx = 3 tiles long (forward is negative X)
			# Y: from (cy - 2) to (cy + 1) = 4 tiles wide
			for x_offset in range(-2, 1):  # -2, -1, 0 = 3 tiles
				for y_offset in range(-2, 2):  # -2, -1, 0, 1 = 4 tiles
					tiles.append(Position.create(
						center_position.x + x_offset,
						center_position.y + y_offset
					))
		
		Direction.RIGHT:
			# Facing EAST: 4 wide (Y axis), 3 long forward (positive X)
			# X: from cx to (cx + 2) = 3 tiles long (forward is positive X)
			# Y: from (cy - 2) to (cy + 1) = 4 tiles wide
			for x_offset in range(0, 3):  # 0, 1, 2 = 3 tiles
				for y_offset in range(-2, 2):  # -2, -1, 0, 1 = 4 tiles
					tiles.append(Position.create(
						center_position.x + x_offset,
						center_position.y + y_offset
					))
	
	return tiles

## Get all occupied tile positions
func get_occupied_tiles() -> Array:
	return _occupied_tiles.duplicate()

## Check if this hitbox contains a given position
func contains_position(pos: Position) -> bool:
	for tile in _occupied_tiles:
		if tile.equals(pos):
			return true
	return false

## String representation for debugging
func _to_string() -> String:
	return "TankHitbox(center=%s, direction=%s, tiles=%d)" % [
		center_position,
		direction,
		_occupied_tiles.size()
	]
