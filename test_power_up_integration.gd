extends Node2D
# Quick integration test for power-up spawning
# Run this scene to visually verify power-ups spawn when killing armored tanks

var player_tank
var enemy_tank
var power_up_manager

func _ready():
	print("\n=== Power-Up Integration Test ===")
	
	# Create PowerUpManager
	power_up_manager = load("res://src/managers/power_up_manager.gd").new()
	add_child(power_up_manager)
	print("✓ PowerUpManager created and subscribed to TankDestroyed events")
	
	# Wait a moment then destroy the tank
	await get_tree().create_timer(0.2).timeout
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
	await get_tree().create_timer(0.5).timeout
	
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
	await get_tree().create_timer(1.0).timeout
	print("\n--- Simulating Basic tank destruction (should NOT spawn) ---")
	
	var event2 = TankDestroyedEvent.new()
	event2.tank_type = "Basic"
	event2.position = Vector2(300, 200)
	event2.tank_id = 67890
	event2.was_player = false
	event2.score_value = 100
	EventBus.emit_game_event(event2)
	print("✓ TankDestroyedEvent emitted for Basic tank")
	
	await get_tree().create_timer(0.5).timeout
	
	var power_ups_after = get_tree().get_nodes_in_group("power_ups")
	print("\nPower-ups after basic tank destroyed: ", power_ups_after.size())
	
	if power_ups_after.size() == power_ups.size():
		print("✓ SUCCESS! Basic tank correctly did NOT spawn power-up")
	else:
		print("✗ FAILED! Basic tank spawned power-up (should only be Armored)")
	
	print("\n=== Test Complete ===")
	
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()
