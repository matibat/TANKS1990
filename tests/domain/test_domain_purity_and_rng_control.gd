extends GutTest
## Domain purity and RNG control checks

const GameLoop = preload("res://src/domain/game_loop.gd")
const GameState = preload("res://src/domain/aggregates/game_state.gd")
const StageState = preload("res://src/domain/aggregates/stage_state.gd")
const TankEntity = preload("res://src/domain/entities/tank_entity.gd")
const BulletEntity = preload("res://src/domain/entities/bullet_entity.gd")
const SpawnController = preload("res://src/domain/services/spawn_controller.gd")
const AIService = preload("res://src/domain/services/ai_service.gd")
const Position = preload("res://src/domain/value_objects/position.gd")
const Direction = preload("res://src/domain/value_objects/direction.gd")

## BDD: Given domain types When instantiated Then they remain engine-free
func test_given_domain_types_when_instantiated_then_extend_refcounted_not_node():
	var stage = StageState.create(1, 26, 26)
	stage.set_base(Position.create(12, 24))
	var instances = [
		GameLoop.new(),
		GameState.create(stage, 3),
		StageState.create(1, 26, 26),
		TankEntity.create("t1", TankEntity.Type.PLAYER, Position.create(0, 0), Direction.create(Direction.UP)),
		BulletEntity.create("b1", "t1", Position.create(0, 0), Direction.create(Direction.UP), 1, 1)
	]
	for inst in instances:
		assert_true(inst is RefCounted, "%s should be RefCounted" % inst.get_class())
		assert_false(inst is Node, "%s should not inherit Node" % inst.get_class())

## BDD: Given game loop source When scanned Then no Godot singletons are referenced
func test_given_game_loop_source_when_scanned_then_no_singletons_present():
	var loop = GameLoop.new()
	var source = loop.get_script().get_source_code()
	var forbidden = ["Engine.", "Input.", "OS.", "ProjectSettings.", "Time.", "DisplayServer.", "AudioServer.", "SceneTree."]
	for name in forbidden:
		assert_eq(source.find(name), -1, "GameLoop should stay engine-free; found forbidden reference to %s" % name)

## BDD: Given RNG-dependent services When requesting deterministic control Then API must exist
func test_given_spawn_and_ai_services_when_requesting_seed_control_then_api_exists():
	var spawn = SpawnController.new(1)
	var ai = AIService.new()
	var spawn_seedable = spawn.has_method("set_rng") or spawn.has_method("set_random_provider")
	var ai_seedable = ai.has_method("set_rng") or ai.has_method("set_random_provider")
	assert_true(spawn_seedable, "SpawnController should expose RNG injection for deterministic spawning")
	assert_true(ai_seedable, "AIService should expose RNG injection for deterministic AI")
