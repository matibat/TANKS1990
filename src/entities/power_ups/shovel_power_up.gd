extends PowerUp
class_name ShovelPowerUp
# Shovel power-up: Fortifies base walls with steel for 10 seconds

@export var fortification_time: float = 10.0

func _ready():
	power_up_type = "Shovel"
	super._ready()

func _create_placeholder_visual():
	var sprite = ColorRect.new()
	sprite.size = Vector2(32, 32)
	sprite.position = Vector2(-16, -16)
	sprite.color = Color.GRAY  # Gray for steel walls
	add_child(sprite)

func apply_effect(tank):
	# Fortify base walls with steel
	var terrain_manager = get_tree().get_first_node_in_group("terrain_manager")
	if not terrain_manager:
		push_warning("TerrainManager not found for shovel power-up")
		return
	
	# Base position at (208, 400) → tiles around (13, 25)
	# Fortify 3x3 area around base
	var base_tile_x = 13
	var base_tile_y = 25
	
	var tiles_to_fortify = []
	for x in range(base_tile_x - 1, base_tile_x + 2):
		for y in range(base_tile_y - 1, base_tile_y + 2):
			if x >= 0 and x < 26 and y >= 0 and y < 26:
				var current_type = terrain_manager.get_tile_type_at_coords(x, y)
				tiles_to_fortify.append({"x": x, "y": y, "original": current_type})
				terrain_manager.set_tile_at_coords(x, y, terrain_manager.TileType.STEEL)
	
	# Schedule reversion after fortification_time seconds
	await get_tree().create_timer(fortification_time).timeout
	
	# Revert to original tiles (usually brick)
	for tile_data in tiles_to_fortify:
		if terrain_manager and is_instance_valid(terrain_manager):
			var revert_type = terrain_manager.TileType.BRICK  # Default to brick
			terrain_manager.set_tile_at_coords(tile_data.x, tile_data.y, revert_type)
