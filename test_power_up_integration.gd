extends Node2D
# Quick integration test for power-up spawning
# Run this scene to visually verify power-ups spawn when killing armored tanks

var player_tank
var enemy_tank
var power_up_manager

# Timers for test sequencing
var initial_wait_timer: Timer
var spawn_wait_timer: Timer
var basic_tank_wait_timer: Timer
var final_wait_timer: Timer

func _ready():
	print("\n=== Power-Up Integration Test ===")
	
	# Create PowerUpManager
	power_up_manager = load("res://src/managers/power_up_manager.gd").new()
	add_child(power_up_manager)
	print("✓ PowerUpManager created and subscribed to TankDestroyed events")
	
	# Create timers for test sequencing
	initial_wait_timer = Timer.new()
	initial_wait_timer.wait_time = 0.2
	initial_wait_timer.one_shot = true
	add_child(initial_wait_timer)
	initial_wait_timer.timeout.connect(_on_initial_wait_done)
	initial_wait_timer.start()
	
func _on_initial_wait_done():
	print("\n--- Simulating Armored tank destruction ---")
	
	# Emit TankDestroyedEvent
	var TankDestroyedEvent = load("res://src/events/tank_destroyed_event.gd")
	var event = TankDestroyedEvent.new()
	event.tank_type = "Armored"
	event.position = Vector2(200, 200)
	event.tank_id = 12345
	event.was_player = false
	event.score_value = 400
	EventBus.emit_game_event(event)
	print("✓ TankDestroyedEvent emitted for Armored tank at (200, 200)")
	
	# Wait for power-up to spawn
	spawn_wait_timer = Timer.new()
	spawn_wait_timer.wait_time = 0.5
	spawn_wait_timer.one_shot = true
	add_child(spawn_wait_timer)
	spawn_wait_timer.timeout.connect(_on_spawn_wait_done)
	spawn_wait_timer.start()

func _on_spawn_wait_done():
	# Check for power-ups
	var power_ups = get_tree().get_nodes_in_group("power_ups")
	print("\n=== Results ===")
	print("Power-ups spawned: ", power_ups.size())
	
	if power_ups.size() > 0:
		print("✓ SUCCESS! Power-up spawned at: ", power_ups[0].global_position)
		print("  Type: ", power_ups[0].power_up_type)
		print("\nVisual test: You should see a colored square at position (200, 200)")
	else:
		print("✗ FAILED! No power-up spawned")
		print("\nDebugging info:")
		print("  PowerUpManager valid: ", is_instance_valid(power_up_manager))
		print("  PowerUpManager parent: ", power_up_manager.get_parent())
		print("  Scene tree root: ", get_tree().root)
		print("  Current scene: ", get_tree().current_scene)
	
	# Test with Basic tank (should NOT spawn power-up)
	basic_tank_wait_timer = Timer.new()
	basic_tank_wait_timer.wait_time = 1.0
	basic_tank_wait_timer.one_shot = true
	add_child(basic_tank_wait_timer)
	basic_tank_wait_timer.timeout.connect(_on_basic_tank_wait_done)
	basic_tank_wait_timer.start()

func _on_basic_tank_wait_done():
	print("\n--- Simulating Basic tank destruction (should NOT spawn) ---")
	
	var TankDestroyedEvent = load("res://src/events/tank_destroyed_event.gd")
	var event2 = TankDestroyedEvent.new()
	event2.tank_type = "Basic"
	event2.position = Vector2(300, 200)
	event2.tank_id = 67890
	event2.was_player = false
	event2.score_value = 100
	EventBus.emit_game_event(event2)
	print("✓ TankDestroyedEvent emitted for Basic tank")
	
	final_wait_timer = Timer.new()
	final_wait_timer.wait_time = 0.5
	final_wait_timer.one_shot = true
	add_child(final_wait_timer)
	final_wait_timer.timeout.connect(_on_final_wait_done)
	final_wait_timer.start()

func _on_final_wait_done():
	var power_ups_after = get_tree().get_nodes_in_group("power_ups")
	print("\nPower-ups after basic tank destroyed: ", power_ups_after.size())
	
	if power_ups_after.size() == get_tree().get_nodes_in_group("power_ups").size():
		print("✓ SUCCESS! Basic tank correctly did NOT spawn power-up")
	else:
		print("✗ FAILED! Basic tank spawned power-up (should only be Armored)")
	
	print("\n=== Test Complete ===")
	
	get_tree().quit()

func _exit_tree():
	# Cancel all timers to prevent keeping SceneTree alive
	if initial_wait_timer and is_instance_valid(initial_wait_timer):
		initial_wait_timer.stop()
	if spawn_wait_timer and is_instance_valid(spawn_wait_timer):
		spawn_wait_timer.stop()
	if basic_tank_wait_timer and is_instance_valid(basic_tank_wait_timer):
		basic_tank_wait_timer.stop()
	if final_wait_timer and is_instance_valid(final_wait_timer):
		final_wait_timer.stop()
