class_name TerrainManager
extends TileMapLayer
## Manages destructible terrain tiles

enum TileType { EMPTY = -1, BRICK = 0, STEEL = 1, WATER = 2, FOREST = 3, ICE = 4 }

# Tile atlas coordinates
const TILE_COORDS = {
	TileType.BRICK: Vector2i(0, 0),
	TileType.STEEL: Vector2i(1, 0),
	TileType.WATER: Vector2i(2, 0),
	TileType.FOREST: Vector2i(3, 0),
	TileType.ICE: Vector2i(4, 0)
}

# Tile properties
const DESTRUCTIBLE_TILES = [TileType.BRICK]
const SOLID_TILES = [TileType.BRICK, TileType.STEEL, TileType.WATER]
const PASSABLE_TILES = [TileType.FOREST, TileType.ICE]

signal tile_destroyed(tile_pos: Vector2i, tile_type: TileType)
signal tile_damaged(tile_pos: Vector2i, tile_type: TileType)

func _ready() -> void:
	# Set collision layers
	collision_enabled = true
	collision_layer = 2  # Terrain layer
	collision_mask = 0   # Doesn't need to detect anything

## Get tile type at world position
func get_tile_at_position(world_pos: Vector2) -> TileType:
	var tile_pos = local_to_map(to_local(world_pos))
	var tile_data = get_cell_tile_data(tile_pos)
	
	if tile_data == null:
		return TileType.EMPTY
	
	var atlas_coords = get_cell_atlas_coords(tile_pos)
	
	# Find matching tile type
	for type in TILE_COORDS:
		if TILE_COORDS[type] == atlas_coords:
			return type
	
	return TileType.EMPTY

## Check if tile is solid (blocks movement)
func is_tile_solid(world_pos: Vector2) -> bool:
	var tile_type = get_tile_at_position(world_pos)
	return tile_type in SOLID_TILES

## Check if tile is destructible
func is_tile_destructible(world_pos: Vector2) -> bool:
	var tile_type = get_tile_at_position(world_pos)
	return tile_type in DESTRUCTIBLE_TILES

## Damage tile at world position
func damage_tile(world_pos: Vector2, can_destroy_steel: bool = false) -> bool:
	var tile_pos = local_to_map(to_local(world_pos))
	var tile_type = get_tile_at_position(world_pos)
	
	if tile_type == TileType.EMPTY:
		return false
	
	# Check if tile can be destroyed
	if tile_type == TileType.STEEL and not can_destroy_steel:
		tile_damaged.emit(tile_pos, tile_type)
		return false
	
	if tile_type in DESTRUCTIBLE_TILES or (tile_type == TileType.STEEL and can_destroy_steel):
		# Destroy tile
		erase_cell(tile_pos)
		tile_destroyed.emit(tile_pos, tile_type)
		
		# Emit collision event
		var event = CollisionEvent.new()
		event.position = world_pos
		event.collision_type = "bullet_terrain"
		event.destroyed = true
		EventBus.emit_game_event(event)
		
		return true
	
	return false

## Set tile at world position
func set_tile_at_position(world_pos: Vector2, tile_type: TileType) -> void:
	if tile_type == TileType.EMPTY:
		return
	
	var tile_pos = local_to_map(to_local(world_pos))
	set_cell(tile_pos, 0, TILE_COORDS[tile_type])

## Set tile at grid coordinates
func set_tile_at_coords(tile_x: int, tile_y: int, tile_type: TileType) -> void:
	if tile_type == TileType.EMPTY:
		erase_cell(Vector2i(tile_x, tile_y))
		return
	
	set_cell(Vector2i(tile_x, tile_y), 0, TILE_COORDS[tile_type])

## Get tile type at grid coordinates
func get_tile_at_coords(tile_x: int, tile_y: int) -> TileType:
	var tile_pos = Vector2i(tile_x, tile_y)
	var tile_data = get_cell_tile_data(tile_pos)
	
	if tile_data == null:
		return TileType.EMPTY
	
	var atlas_coords = get_cell_atlas_coords(tile_pos)
	
	for type in TILE_COORDS:
		if TILE_COORDS[type] == atlas_coords:
			return type
	
	return TileType.EMPTY

## Load terrain from 2D array
func load_terrain_from_array(terrain_data: Array) -> void:
	clear()
	
	for y in range(terrain_data.size()):
		var row = terrain_data[y]
		for x in range(row.size()):
			var tile_type = row[x] as TileType
			if tile_type != TileType.EMPTY:
				set_tile_at_coords(x, y, tile_type)

## Export terrain to 2D array
func export_terrain_to_array(width: int = 26, height: int = 26) -> Array:
	var terrain_data = []
	
	for y in range(height):
		var row = []
		for x in range(width):
			row.append(get_tile_at_coords(x, y))
		terrain_data.append(row)
	
	return terrain_data

## Clear all tiles
func clear_terrain() -> void:
	clear()

## Check if position is in bounds
func is_in_bounds(world_pos: Vector2) -> bool:
	var tile_pos = local_to_map(to_local(world_pos))
	return tile_pos.x >= 0 and tile_pos.x < 26 and tile_pos.y >= 0 and tile_pos.y < 26
