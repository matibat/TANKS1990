extends Node3D
class_name GameController3D
## 3D Game Controller - manages player, enemies, and game loop

# Preload required scenes and scripts
const ENEMY_SCENE = preload("res://scenes3d/enemy_tank3d.tscn")
const SimpleAI3D = preload("res://scenes3d/simple_ai_3d.gd")

# References
var player_tank: Tank3D = null
var camera: Camera3D = null
var enemies_container: Node3D = null
var bullet_manager: Node3D = null

# Map configuration
const MAP_MIN = 0.0
const MAP_MAX = 26.0
const TANK_HALF_SIZE = 0.5

# Enemy spawning

func _ready() -> void:
	# Find references
	player_tank = _find_player_tank()
	camera = _find_camera()
	enemies_container = _find_or_create_enemies_container()
	bullet_manager = _find_or_create_bullet_manager()
	
	# Setup player
	if player_tank:
		print("✓ Player tank found at: ", player_tank.global_position)
		player_tank.visible = true
	else:
		push_error("❌ Player tank not found!")
	
	# Setup camera
	if camera:
		print("✓ Camera found at: ", camera.global_position)
	
	# Spawn test enemies
	spawn_test_enemies()
	
	print("=== 3D Game Controller Ready ===")
	print("Use Arrow Keys to move, Space to shoot")

func _physics_process(_delta: float) -> void:
	if player_tank and is_instance_valid(player_tank):
		_handle_player_input()
		_clamp_tank_to_bounds(player_tank)
		_update_camera_follow()  # Make camera follow player
	
	# Clamp all enemies
	if enemies_container:
		for enemy in enemies_container.get_children():
			if enemy is Tank3D:
				_clamp_tank_to_bounds(enemy)

func _update_camera_follow() -> void:
	"""Make camera follow player tank position"""
	if not camera or not player_tank:
		return
	
	# Camera should follow player (centered, with vertical offset)
	var target_pos = player_tank.global_position
	target_pos.y = 10.0  # Fixed height above ground
	
	# Smooth follow or instant (instant for now to avoid lag)
	camera.global_position = target_pos

func _handle_player_input() -> void:
	# Convert 2D input to 3D direction (X/Z plane)
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_dir.length() > 0:
		# X axis = left/right, Z axis = up/down (negative Z = up in world space)
		var direction_3d = Vector3(input_dir.x, 0, input_dir.y)
		player_tank.set_movement_direction(direction_3d)
	else:
		player_tank.set_movement_direction(Vector3.ZERO)
	
	# Shooting
	if Input.is_action_just_pressed("fire"):
		player_tank.try_fire()

func _clamp_tank_to_bounds(tank: Tank3D) -> void:
	var pos = tank.global_position
	pos.x = clampf(pos.x, MAP_MIN + TANK_HALF_SIZE, MAP_MAX - TANK_HALF_SIZE)
	pos.z = clampf(pos.z, MAP_MIN + TANK_HALF_SIZE, MAP_MAX - TANK_HALF_SIZE)
	pos.y = 0.0  # Keep on ground plane
	tank.global_position = pos

func spawn_test_enemies() -> void:
	if not enemies_container:
		return
	
	print("Spawning test enemies...")
	
	# Spawn 3 test enemies
	var positions = [
		Vector3(2, 0, 2),
		Vector3(24, 0, 2),
		Vector3(13, 0, 5)
	]
	
	for pos in positions:
		var enemy = ENEMY_SCENE.instantiate()
		enemies_container.add_child(enemy)
		enemy.global_position = pos
		enemy.tank_type = Tank3D.TankType.BASIC
		
		# Add AI controller
		var ai = SimpleAI3D.new()
		ai.tank = enemy
		if player_tank:
			ai.target = player_tank
		enemy.add_child(ai)
		
		print("  Enemy spawned at: ", pos)

func _find_player_tank() -> Tank3D:
	# Search for player tank in common locations
	var search_paths = [
		"PlayerTank3D",
		"../PlayerTank3D",
		"GameplayLayer/PlayerTank3D",
		"../GameplayLayer/PlayerTank3D"
	]
	
	for path in search_paths:
		if has_node(path):
			var tank = get_node(path)
			if tank is Tank3D:
				return tank
	
	# Search all children recursively
	return _find_tank_recursive(get_parent(), true)

func _find_tank_recursive(node: Node, is_player: bool) -> Tank3D:
	if node is Tank3D:
		var tank = node as Tank3D
		if tank.is_player == is_player:
			return tank
	
	for child in node.get_children():
		var result = _find_tank_recursive(child, is_player)
		if result:
			return result
	
	return null

func _find_camera() -> Camera3D:
	# Search for camera
	if has_node("Camera3D"):
		return get_node("Camera3D")
	if has_node("../Camera3D"):
		return get_node("../Camera3D")
	
	# Search in parent
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child is Camera3D:
				return child
	
	return null

func _find_or_create_enemies_container() -> Node3D:
	if has_node("Enemies"):
		return get_node("Enemies")
	
	# Create container
	var container = Node3D.new()
	container.name = "Enemies"
	add_child(container)
	return container

func _find_or_create_bullet_manager() -> Node3D:
	if has_node("BulletManager3D"):
		return get_node("BulletManager3D")
	
	if has_node("../BulletManager3D"):
		return get_node("../BulletManager3D")
	
	# Check parent
	var parent = get_parent()
	if parent and parent.has_node("BulletManager3D"):
		return parent.get_node("BulletManager3D")
	
	return null
