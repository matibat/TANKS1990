extends Node2D
## Main test scene for player tank movement and enemy AI

@onready var player_tank: Tank = $PlayerTank
@onready var debug_label: Label = $UI/DebugLabel
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var bullet_manager: Node = $BulletManager

var show_collision_shapes: bool = false
var enemy_ai_controllers: Array = []
var base_position: Vector2 = Vector2(416, 750)  # Bottom center

func _ready() -> void:
	# Reduce spawn time for testing
	if player_tank:
		player_tank.spawn_timer = 0.1  # Almost instant spawn
	
	# Enable collision shape visibility in debug
	get_tree().debug_collisions_hint = true
	
	# Setup enemy spawner
	if enemy_spawner:
		# Subscribe to tank spawned events to add AI
		EventBus.subscribe("TankSpawned", _on_enemy_tank_spawned)
		# Start first wave
		enemy_spawner.start_wave(1)
	
	print("Main scene ready - Player tank and enemy spawner initialized")

func _process(_delta: float) -> void:
	if player_tank and debug_label:
		var state_name = Tank.State.keys()[player_tank.current_state]
		var direction_name = Tank.Direction.keys()[player_tank.facing_direction]
		var enemy_count = get_tree().get_nodes_in_group("enemies").size()
		var ai_count = enemy_ai_controllers.size()
		
		debug_label.text = "Tank 1990 - Test Scene
WASD/Arrows: Move
Space: Fire
ESC: Quit
F3: Toggle Collision Shapes [%s]

State: %s
Direction: %s
Position: %s
Velocity: %s
Enemies: %d (AI: %d)" % ["ON" if show_collision_shapes else "OFF", state_name, direction_name, player_tank.global_position, player_tank.velocity, enemy_count, ai_count]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F3:
			show_collision_shapes = !show_collision_shapes
			get_tree().debug_collisions_hint = show_collision_shapes

func _on_enemy_tank_spawned(event: GameEvent) -> void:
	# Only add AI to enemy tanks, not player
	if event.is_player:
		return
	
	# Wait for tank to be added to scene tree
	await get_tree().process_frame
	
	# Find the spawned enemy tank
	var spawned_tank = null
	for node in get_tree().get_nodes_in_group("enemies"):
		if node.tank_id == event.tank_id:
			spawned_tank = node
			break
	
	if not spawned_tank:
		print("Warning: Could not find spawned enemy tank with ID ", event.tank_id)
		return
	
	# Create and attach AI controller
	var EnemyAIController = load("res://src/controllers/enemy_ai_controller.gd")
	var ai_controller = EnemyAIController.new(spawned_tank)
	add_child(ai_controller)
	ai_controller.initialize(spawned_tank, player_tank, base_position)
	enemy_ai_controllers.append(ai_controller)
	
	print("✓ AI controller added to enemy tank ID ", event.tank_id, " (", event.tank_type, ")")
