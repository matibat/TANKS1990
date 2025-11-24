extends Node
class_name PowerUpManager
# Manages power-up spawning from Armored tank destruction

const POWER_UP_PATHS = [
	"res://src/entities/power_ups/tank_power_up.gd",
	"res://src/entities/power_ups/star_power_up.gd",
	"res://src/entities/power_ups/grenade_power_up.gd",
	"res://src/entities/power_ups/helmet_power_up.gd",
	"res://src/entities/power_ups/clock_power_up.gd",
	"res://src/entities/power_ups/shovel_power_up.gd"
]

func _ready():
	# Subscribe to TankDestroyedEvent
	EventBus.subscribe("TankDestroyedEvent", _on_tank_destroyed)

func _exit_tree():
	# Cleanup subscription
	if EventBus.has_method("unsubscribe"):
		EventBus.unsubscribe("TankDestroyedEvent", _on_tank_destroyed)

func _on_tank_destroyed(event):
	# Only spawn power-up from Armored tanks
	if event.tank_type != "Armored":
		return
	
	# Spawn random power-up at tank position
	spawn_power_up(event.position)

func spawn_power_up(position: Vector2):
	# Randomly select power-up type
	var random_index = randi() % POWER_UP_PATHS.size()
	var power_up_path = POWER_UP_PATHS[random_index]
	
	# Load and instantiate power-up
	var PowerUpClass = load(power_up_path)
	var power_up = PowerUpClass.new()
	power_up.global_position = position
	
	# Add to scene tree
	get_tree().current_scene.add_child(power_up)
	
	# Emit PowerUpSpawnedEvent
	_emit_spawned_event(power_up)

func _emit_spawned_event(power_up):
	var event = load("res://src/events/powerup_spawned_event.gd").new()
	event.power_up_type = power_up.power_up_type
	event.position = power_up.global_position
	event.frame = EventBus.current_frame
	EventBus.emit_game_event(event)
