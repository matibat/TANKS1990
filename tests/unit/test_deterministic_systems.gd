extends GutTest
# BDD: Deterministic systems stay reproducible with fixed seed

const EnemySpawnerScript = preload("res://src/managers/enemy_spawner.gd")
const PowerUpManagerScript = preload("res://src/managers/power_up_manager.gd")

func test_given_seed_when_generating_enemy_queue_then_order_repeats():
	# Given: Fixed seed and two spawners
	RandomProvider.set_seed(55)
	var spawner_one = EnemySpawnerScript.new()
	add_child_autofree(spawner_one)
	spawner_one.start_wave(2)
	var queue_one = spawner_one.enemy_queue.duplicate(true)
	
	RandomProvider.set_seed(55)
	var spawner_two = EnemySpawnerScript.new()
	add_child_autofree(spawner_two)
	spawner_two.start_wave(2)
	var queue_two = spawner_two.enemy_queue.duplicate(true)
	
	# Then: Queues match exactly
	assert_eq(queue_one, queue_two, "Enemy queue should be deterministic for a fixed seed")

func test_given_seed_when_spawning_power_up_then_type_repeats():
	# Given: A fixed seed
	var type_one = await _spawn_power_up_with_seed(77)
	var type_two = await _spawn_power_up_with_seed(77)
	
	# Then: Same power-up is chosen
	assert_eq(type_one, type_two, "Power-up selection should repeat with the same seed")

func test_event_bus_seed_sets_random_provider_seed():
	# Given: Seed change via EventBus
	EventBus.set_game_seed(4242)
	
	# Then: RandomProvider reflects the new seed
	assert_eq(RandomProvider.get_seed(), 4242, "RandomProvider seed should mirror EventBus seed")

func _spawn_power_up_with_seed(seed: int) -> String:
	RandomProvider.set_seed(seed)
	var manager = PowerUpManagerScript.new()
	add_child_autofree(manager)
	manager.spawn_power_up(Vector2.ZERO)
	await wait_physics_frames(1)
	var power_ups = get_tree().get_nodes_in_group("power_ups")
	var type_name := ""
	if power_ups.size() > 0:
		type_name = power_ups[0].power_up_type
		for power_up in power_ups:
			power_up.queue_free()
	manager.queue_free()
	return type_name
