class_name GridMovementService
extends RefCounted

## Grid Movement Service
## Handles grid-based movement with half-tile precision for Tank 1990
## Part of Phase 1.2 implementation

const TILE_SIZE = 16
const HALF_TILE = 8
const SUBTILE_SIZE = 4

## Snap a pixel position to the nearest half-tile boundary (8-pixel grid)
static func snap_to_half_tile(pixel_pos: Vector2) -> Vector2:
	var x = round(pixel_pos.x / HALF_TILE) * HALF_TILE
	var y = round(pixel_pos.y / HALF_TILE) * HALF_TILE
	return Vector2(x, y)

## Calculate the next half-tile position in the given direction
static func calculate_next_half_tile(current_pos: Vector2, direction: int) -> Vector2:
	const Direction = preload("res://src/domain/value_objects/direction.gd")
	
	var next_pos = current_pos
	match direction:
		Direction.UP:
			next_pos.y -= HALF_TILE
		Direction.DOWN:
			next_pos.y += HALF_TILE
		Direction.LEFT:
			next_pos.x -= HALF_TILE
		Direction.RIGHT:
			next_pos.x += HALF_TILE
	
	return next_pos

## Check if a position is on a half-tile boundary (multiple of 8)
static func is_on_half_tile_boundary(pixel_pos: Vector2) -> bool:
	var x_aligned = int(pixel_pos.x) % HALF_TILE == 0
	var y_aligned = int(pixel_pos.y) % HALF_TILE == 0
	return x_aligned and y_aligned

## Convert pixel position to tile coordinates
static func pixel_to_tile(pixel_pos: Vector2) -> Vector2i:
	var tile_x = int(pixel_pos.x / TILE_SIZE)
	var tile_y = int(pixel_pos.y / TILE_SIZE)
	return Vector2i(tile_x, tile_y)

## Convert tile coordinates to pixel position (top-left corner of tile)
static func tile_to_pixel(tile_coords: Vector2i) -> Vector2:
	var pixel_x = tile_coords.x * TILE_SIZE
	var pixel_y = tile_coords.y * TILE_SIZE
	return Vector2(pixel_x, pixel_y)
