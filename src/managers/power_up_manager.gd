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
	# Subscribe to TankDestroyed event
	EventBus.subscribe("TankDestroyed", _on_tank_destroyed)

func _exit_tree():
	# Cleanup subscription
	if EventBus.has_method("unsubscribe"):
		EventBus.unsubscribe("TankDestroyed", _on_tank_destroyed)

func _on_tank_destroyed(event):
	# Only spawn power-up from Armored tanks
	if event.tank_type != "Armored":
		return
	
	# Spawn random power-up at tank position
	spawn_power_up(event.position)

func spawn_power_up(position: Vector2):
	# Randomly select power-up type
	var power_up_path = RandomProvider.choice(POWER_UP_PATHS)
	
	# Load and instantiate power-up
	var PowerUpClass = load(power_up_path)
	var power_up = PowerUpClass.new()
	power_up.global_position = position
	
	# Add to scene tree - try multiple parent options
	var parent_node = null
	if get_tree():
		# Try current scene first
		if get_tree().current_scene:
			parent_node = get_tree().current_scene
		# Try root if no current scene
		elif get_tree().root:
			parent_node = get_tree().root
		# Try self's parent as fallback
		elif get_parent():
			parent_node = get_parent()
	
	if parent_node:
		parent_node.add_child(power_up)
	else:
		push_warning("PowerUpManager: No valid parent for power-up spawn")
		return
	
	# Emit PowerUpSpawnedEvent
	_emit_spawned_event(power_up)

func _emit_spawned_event(power_up):
	var event = load("res://src/events/powerup_spawned_event.gd").new()
	# Map string power_up_type to enum PowerUpType
	var type_name = power_up.power_up_type
	var PowerUpEventClass = load("res://src/events/powerup_spawned_event.gd")
	var powerup_enum = PowerUpEventClass.PowerUpType.STAR  # Default
	match type_name:
		"Star": powerup_enum = PowerUpEventClass.PowerUpType.STAR
		"Grenade": powerup_enum = PowerUpEventClass.PowerUpType.GRENADE
		"Helmet": powerup_enum = PowerUpEventClass.PowerUpType.HELMET
		"Shovel": powerup_enum = PowerUpEventClass.PowerUpType.SHOVEL
		"Tank": powerup_enum = PowerUpEventClass.PowerUpType.TANK
		"Clock": powerup_enum = PowerUpEventClass.PowerUpType.TIMER
	
	event.powerup_type = powerup_enum
	event.powerup_id = power_up.get_instance_id()
	event.position = power_up.global_position
	event.frame = EventBus.current_frame
	EventBus.emit_game_event(event)
