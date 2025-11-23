extends Node2D
## Main test scene for player tank movement

@onready var player_tank: Tank = $PlayerTank
@onready var debug_label: Label = $UI/DebugLabel

var show_collision_shapes: bool = false

func _ready() -> void:
	# Reduce spawn time for testing
	if player_tank:
		player_tank.spawn_timer = 0.1  # Almost instant spawn
	
	# Enable collision shape visibility in debug
	get_tree().debug_collisions_hint = true

func _process(_delta: float) -> void:
	if player_tank and debug_label:
		var state_name = Tank.State.keys()[player_tank.current_state]
		var direction_name = Tank.Direction.keys()[player_tank.facing_direction]
		debug_label.text = "Tank 1990 - Test Scene
WASD/Arrows: Move
Space: Fire
ESC: Quit
F3: Toggle Collision Shapes [%s]

State: %s
Direction: %s
Position: %s
Velocity: %s" % ["ON" if show_collision_shapes else "OFF", state_name, direction_name, player_tank.global_position, player_tank.velocity]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F3:
			show_collision_shapes = !show_collision_shapes
			get_tree().debug_collisions_hint = show_collision_shapes
