class_name TerrainManager
extends TileMapLayer
## Manages destructible terrain tiles

enum TileType { EMPTY = -1, BRICK = 0, STEEL = 1, WATER = 2, FOREST = 3, ICE = 4 }

# Map dimensions (26x26 tiles)
const MAP_WIDTH_TILES: int = 26
const MAP_HEIGHT_TILES: int = 26

# Tile atlas coordinates
const TILE_COORDS = {
	TileType.BRICK: Vector2i(0, 0),
	TileType.STEEL: Vector2i(1, 0),
	TileType.WATER: Vector2i(2, 0),
	TileType.FOREST: Vector2i(3, 0),
	TileType.ICE: Vector2i(4, 0)
}

# Internal tile storage for testing without TileSet
# Key: Vector2i(x, y), Value: TileType
var _tile_cache: Dictionary = {}

# Tile properties
const DESTRUCTIBLE_TILES = [TileType.BRICK]
const SOLID_TILES = [TileType.BRICK, TileType.STEEL, TileType.WATER]
const PASSABLE_TILES = [TileType.FOREST, TileType.ICE]

signal tile_destroyed(tile_pos: Vector2i, tile_type: TileType)
signal tile_damaged(tile_pos: Vector2i, tile_type: TileType)

func _ready() -> void:
	# TileMapLayer has collision enabled by default
	# Collision layers are controlled by the TileSet physics layers
	_create_placeholder_tileset()

func _create_placeholder_tileset() -> void:
	"""Create a simple colored tile set for visual feedback until sprites are added"""
	# Create TileSet if not already configured
	if tile_set == null or tile_set.get_source_count() == 0:
		var new_tileset = TileSet.new()
		new_tileset.tile_size = Vector2i(16, 16)
		
		# Add physics layer FIRST before creating tiles
		new_tileset.add_physics_layer()
		new_tileset.set_physics_layer_collision_layer(0, 2)  # Layer 2 for terrain
		new_tileset.set_physics_layer_collision_mask(0, 0)
		
		# Create TileSetAtlasSource
		var atlas_source = TileSetAtlasSource.new()
		
		# Create a simple placeholder texture (5x1 atlas for 5 tile types)
		var img = Image.create(80, 16, false, Image.FORMAT_RGBA8)
		
		# Fill with colors for each tile type
		# BRICK (0,0) - Red/Brown
		img.fill_rect(Rect2i(0, 0, 16, 16), Color(0.6, 0.3, 0.2, 1.0))
		# STEEL (1,0) - Gray
		img.fill_rect(Rect2i(16, 0, 16, 16), Color(0.5, 0.5, 0.5, 1.0))
		# WATER (2,0) - Blue
		img.fill_rect(Rect2i(32, 0, 16, 16), Color(0.2, 0.3, 0.8, 1.0))
		# FOREST (3,0) - Green
		img.fill_rect(Rect2i(48, 0, 16, 16), Color(0.2, 0.6, 0.2, 1.0))
		# ICE (4,0) - Cyan
		img.fill_rect(Rect2i(64, 0, 16, 16), Color(0.7, 0.9, 1.0, 1.0))
		
		var texture = ImageTexture.create_from_image(img)
		atlas_source.texture = texture
		atlas_source.texture_region_size = Vector2i(16, 16)
		
		# Create tiles for each type
		for i in range(5):
			var coords = Vector2i(i, 0)
			atlas_source.create_tile(coords)
			# Add physics layer for collision (now layer 0 exists)
			var tile_data = atlas_source.get_tile_data(coords, 0)
			if tile_data:
				tile_data.set_collision_polygons_count(0, 1)
				var polygon = PackedVector2Array([
					Vector2(0, 0), Vector2(16, 0), Vector2(16, 16), Vector2(0, 16)
				])
				tile_data.set_collision_polygon_points(0, 0, polygon)
		
		new_tileset.add_source(atlas_source, 0)
		
		tile_set = new_tileset
		print("Created placeholder tileset with colored tiles")

## Get tile type at world position
func get_tile_at_position(world_pos: Vector2) -> TileType:
	var tile_pos = local_to_map(to_local(world_pos))
	return get_tile_at_coords(tile_pos.x, tile_pos.y)

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
		# Destroy tile using set_tile_at_coords to update cache
		set_tile_at_coords(tile_pos.x, tile_pos.y, TileType.EMPTY)
		tile_destroyed.emit(tile_pos, tile_type)
		
		# Emit collision event
		var event = CollisionEvent.new()
		event.position = world_pos
		event.collider_type = CollisionEvent.ColliderType.TERRAIN
		event.result = "destroy"
		EventBus.emit_game_event(event)
		
		return true
	
	return false

## Set tile at world position
func set_tile_at_position(world_pos: Vector2, tile_type: TileType) -> void:
	var tile_pos = local_to_map(to_local(world_pos))
	set_tile_at_coords(tile_pos.x, tile_pos.y, tile_type)

## Set tile at grid coordinates
func set_tile_at_coords(tile_x: int, tile_y: int, tile_type: TileType) -> void:
	var tile_pos = Vector2i(tile_x, tile_y)
	
	# Update internal cache
	if tile_type == TileType.EMPTY:
		_tile_cache.erase(tile_pos)
	else:
		_tile_cache[tile_pos] = tile_type
	
	# Update TileMapLayer if it has a proper TileSet
	if _has_valid_tileset():
		if tile_type == TileType.EMPTY:
			erase_cell(tile_pos)
		else:
			set_cell(tile_pos, 0, TILE_COORDS[tile_type])

## Get tile type at grid coordinates
func get_tile_at_coords(tile_x: int, tile_y: int) -> TileType:
	var tile_pos = Vector2i(tile_x, tile_y)
	
	# Use cache if TileSet is not properly configured
	if not _has_valid_tileset():
		return _tile_cache.get(tile_pos, TileType.EMPTY)
	
	# Check if cell has any tile set in TileMapLayer
	var source_id = get_cell_source_id(tile_pos)
	if source_id == -1:
		return TileType.EMPTY
	
	var atlas_coords = get_cell_atlas_coords(tile_pos)
	
	for type in TILE_COORDS:
		if TILE_COORDS[type] == atlas_coords:
			return type
	
	return TileType.EMPTY

## Load terrain from flat array (26x26 = 676 elements)
func load_terrain(flat_data: Array) -> void:
	clear()
	
	for i in range(flat_data.size()):
		var x = i % MAP_WIDTH_TILES
		var y = i / MAP_WIDTH_TILES
		var tile_type = flat_data[i] as TileType
		if tile_type != TileType.EMPTY:
			set_tile_at_coords(x, y, tile_type)

## Set tile at coordinate using Vector2i
func set_tile_at_coord(coord: Vector2i, tile_type: TileType) -> void:
	set_tile_at_coords(coord.x, coord.y, tile_type)

## Get tile at coordinate using Vector2i
func get_tile_at_coord(coord: Vector2i) -> TileType:
	return get_tile_at_coords(coord.x, coord.y)

## Check if tile at coordinate is solid
func is_tile_solid_at_coord(coord: Vector2i) -> bool:
	var tile_type = get_tile_at_coord(coord)
	return tile_type in SOLID_TILES

## Load terrain from 2D array
func load_terrain_from_array(terrain_data: Array, auto_enforce_boundaries: bool = true) -> void:
	clear()
	
	var num_rows = terrain_data.size()
	var num_cols = 0
	if num_rows > 0 and terrain_data[0] is Array:
		num_cols = terrain_data[0].size()
	
	for y in range(num_rows):
		var row = terrain_data[y]
		for x in range(row.size()):
			var tile_type = row[x] as TileType
			if tile_type != TileType.EMPTY:
				set_tile_at_coords(x, y, tile_type)
	
	# Enforce steel boundaries after loading (only for full-sized maps)
	if auto_enforce_boundaries and num_rows >= MAP_HEIGHT_TILES and num_cols >= MAP_WIDTH_TILES:
		enforce_boundaries()

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
	_tile_cache.clear()

## Check if position is in bounds
func is_in_bounds(world_pos: Vector2) -> bool:
	var tile_pos = local_to_map(to_local(world_pos))
	return tile_pos.x >= 0 and tile_pos.x < MAP_WIDTH_TILES and tile_pos.y >= 0 and tile_pos.y < MAP_HEIGHT_TILES

## Enforce steel boundaries on all map edges
func enforce_boundaries() -> void:
	# Top and bottom edges
	for x in range(MAP_WIDTH_TILES):
		set_tile_at_coords(x, 0, TileType.STEEL)  # Top edge
		set_tile_at_coords(x, MAP_HEIGHT_TILES - 1, TileType.STEEL)  # Bottom edge
	
	# Left and right edges
	for y in range(MAP_HEIGHT_TILES):
		set_tile_at_coords(0, y, TileType.STEEL)  # Left edge
		set_tile_at_coords(MAP_WIDTH_TILES - 1, y, TileType.STEEL)  # Right edge

## Check if TileSet is properly configured
func _has_valid_tileset() -> bool:
	if tile_set == null:
		return false
	if tile_set.get_source_count() == 0:
		return false
	return true

## Check if map has valid steel boundaries
func has_valid_boundaries() -> bool:
	# Check top and bottom edges
	for x in range(MAP_WIDTH_TILES):
		if get_tile_at_coords(x, 0) != TileType.STEEL:
			return false
		if get_tile_at_coords(x, MAP_HEIGHT_TILES - 1) != TileType.STEEL:
			return false
	
	# Check left and right edges
	for y in range(MAP_HEIGHT_TILES):
		if get_tile_at_coords(0, y) != TileType.STEEL:
			return false
		if get_tile_at_coords(MAP_WIDTH_TILES - 1, y) != TileType.STEEL:
			return false
	
	return true
