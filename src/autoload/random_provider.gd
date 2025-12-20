extends Node
## Deterministic RNG wrapper for gameplay systems

const DEFAULT_SEED: int = 1337

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _choice_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _seed: int = DEFAULT_SEED
var _is_seed_set: bool = false

func set_seed(seed: int) -> void:
	_seed = seed
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed
	_rng.state = seed
	_choice_rng = RandomNumberGenerator.new()
	_choice_rng.seed = seed
	_choice_rng.state = seed
	_is_seed_set = true

func get_seed() -> int:
	return _seed

func randf() -> float:
	_ensure_seed()
	return _rng.randf()

func randi_range(min_value: int, max_value: int) -> int:
	_ensure_seed()
	return _rng.randi_range(min_value, max_value)

func chance(threshold: float) -> bool:
	return randf() < threshold

func choice(items: Array) -> Variant:
	if items.is_empty():
		return null
	_ensure_seed()
	var index := _choice_rng.randi_range(0, items.size() - 1)
	return items[index]

func shuffle(items: Array) -> Array:
	_ensure_seed()
	var copy: Array = items.duplicate(true)
	_shuffle_in_place(copy)
	return copy

func shuffle_in_place(items: Array) -> void:
	_ensure_seed()
	_shuffle_in_place(items)

func _shuffle_in_place(items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp = items[i]
		items[i] = items[j]
		items[j] = tmp

func _ensure_seed() -> void:
	if not _is_seed_set:
		set_seed(DEFAULT_SEED)
