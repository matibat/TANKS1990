extends GutHookScript
## Ensures critical autoload singletons exist for tests and are reset for determinism

# DDD Migration: Legacy autoloads temporarily disabled
const AUTOLOADS = [
	# {"name": "EventBus", "path": "res://src/autoload/event_bus.gd"},
	# {"name": "GameManager", "path": "res://src/autoload/game_manager.gd"},
]

func run():
	var scene_tree := Engine.get_main_loop() as SceneTree
	if scene_tree == null:
		push_error("SceneTree not available in GUT hook")
		return
	var root := scene_tree.root
	for autoload in AUTOLOADS:
		_ensure_autoload(root, autoload.name, autoload.path)
	
	# Allow _ready callbacks to fire
	await scene_tree.process_frame
	
	# Reset EventBus state for deterministic runs
	var event_bus = root.get_node_or_null("/root/EventBus")
	if event_bus:
		if event_bus.has_method("clear_all_listeners"):
			event_bus.clear_all_listeners()
		if event_bus.has_method("stop_replay"):
			event_bus.stop_replay()
		if event_bus.has_method("reset_state"):
			event_bus.reset_state()
		else:
			event_bus.recorded_events.clear()
			event_bus.is_recording = false
			event_bus.is_replaying = false
			event_bus.current_frame = 0
		# DDD Migration: RandomProvider temporarily disabled
		# if event_bus.has_method("set_game_seed"):
		# 	event_bus.set_game_seed(RandomProvider.get_seed())

func _ensure_autoload(root: Node, name: String, path: String) -> void:
	var existing = root.get_node_or_null("/root/%s" % name)
	if existing:
		return
	var script = load(path)
	if script == null:
		push_error("Failed to load autoload script: %s" % path)
		return
	var node = script.new()
	node.name = name
	root.add_child(node)
	root.move_child(node, 0) # keep autoloads ahead of tests
