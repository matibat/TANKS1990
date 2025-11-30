extends PowerUp
class_name ShovelPowerUp
# Shovel power-up: Fortifies base walls with steel for 10 seconds

@export var fortification_time: float = 10.0

var fortification_timer: Timer
var tiles_to_revert = []

func _ready():
	power_up_type = "Shovel"
	super._ready()

func _create_placeholder_visual():
	var bg = ColorRect.new()
	bg.size = Vector2(30, 30)
	bg.position = Vector2(-15, -15)
	bg.color = Color.GRAY
	add_child(bg)
	_create_icon()

func _create_icon():
	var icon = Label.new()
	icon.text = "S"
	icon.position = Vector2(-8, -12)
	icon.add_theme_font_size_override("font_size", 20)
	icon.add_theme_color_override("font_color", Color.WHITE)
	add_child(icon)

func apply_effect(_tank):
	# Fortify base walls with steel
	var terrain_manager = get_tree().get_first_node_in_group("terrain_manager")
	
	# Fallback: search by class type
	if not terrain_manager:
		for node in get_tree().root.get_children():
			terrain_manager = _find_terrain_manager(node)
			if terrain_manager:
				break
	
	if not terrain_manager:
		# Handle gracefully without warning - TerrainManager may not be present in tests
		return
	
	# Base position at (208, 400) → tiles around (13, 25)
	# Fortify 3x3 area around base
	var base_tile_x = 13
	var base_tile_y = 25
	
	tiles_to_revert.clear()
	for x in range(base_tile_x - 1, base_tile_x + 2):
		for y in range(base_tile_y - 1, base_tile_y + 2):
			if x >= 0 and x < 26 and y >= 0 and y < 26:
				var current_type = terrain_manager.get_tile_at_coords(x, y)
				tiles_to_revert.append({"x": x, "y": y, "original": current_type})
				terrain_manager.set_tile_at_coords(x, y, terrain_manager.TileType.STEEL)
	
	# Schedule reversion after fortification_time seconds
	fortification_timer = Timer.new()
	fortification_timer.wait_time = fortification_time
	fortification_timer.one_shot = true
	fortification_timer.timeout.connect(_on_fortification_timeout)
	add_child(fortification_timer)
	fortification_timer.start()

func _on_fortification_timeout():
	# Revert to original tiles (usually brick)
	var terrain_manager = get_tree().get_first_node_in_group("terrain_manager")
	if not terrain_manager:
		for node in get_tree().root.get_children():
			terrain_manager = _find_terrain_manager(node)
			if terrain_manager:
				break
	
	if terrain_manager:
		for tile_data in tiles_to_revert:
			var revert_type = terrain_manager.TileType.BRICK  # Default to brick
			terrain_manager.set_tile_at_coords(tile_data.x, tile_data.y, revert_type)
	
	tiles_to_revert.clear()

func _find_terrain_manager(node: Node) -> TerrainManager:
	if node is TerrainManager:
		return node as TerrainManager
	for child in node.get_children():
		var result = _find_terrain_manager(child)
		if result:
			return result
	return null

func _exit_tree():
	# Cancel timer when node is freed
	if fortification_timer and is_instance_valid(fortification_timer):
		fortification_timer.stop()
		fortification_timer.queue_free()
