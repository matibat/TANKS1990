extends Node3D
## Demo scene script for testing 3D gameplay

# Preload the classes we need
const GameController3D = preload("res://scenes3d/game_controller_3d.gd")
const BulletManager3D = preload("res://src/managers/bullet_manager_3d.gd")

@onready var game_controller: Node3D = $GameController3D if has_node("GameController3D") else null
@onready var bullet_manager: Node3D = $BulletManager3D if has_node("BulletManager3D") else null

func _ready() -> void:
	print("=== 3D DEMO SCENE LOADED ===")
	
	# Create game controller if it doesn't exist
	if not game_controller:
		game_controller = GameController3D.new()
		game_controller.name = "GameController3D"
		add_child(game_controller)
	
	# Create bullet manager if it doesn't exist
	if not bullet_manager:
		bullet_manager = BulletManager3D.new()
		bullet_manager.name = "BulletManager3D"
		add_child(bullet_manager)
	
	print("✓ Game Controller: ", game_controller != null)
	print("✓ Bullet Manager: ", bullet_manager != null)
	print("Press Arrow Keys to move, Space to shoot")
	print("==============================")
