class_name ReplayData
extends Resource
## Container for replay session data with compression support

@export var version: String = "1.0.0"
@export var game_seed: int = 0
@export var player_count: int = 1
@export var stage_id: int = 1
@export var total_frames: int = 0
@export var recording_date: String = ""
@export var events: Array[Dictionary] = []

## Metadata for replay browser
@export var final_score: int = 0
@export var final_stage: int = 1
@export var duration_seconds: float = 0.0

func _init() -> void:
	recording_date = Time.get_datetime_string_from_system()

## Add event to recording
func add_event(event: GameEvent) -> void:
	events.append(event.to_dict())
	total_frames = max(total_frames, event.frame)

## Save replay to file
func save_to_file(path: String) -> Error:
	return ResourceSaver.save(self, path)

## Load replay from file
static func load_from_file(path: String) -> ReplayData:
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path) as ReplayData
	return null

## Get replay duration in seconds
func get_duration() -> float:
	return total_frames / 60.0  # Assuming 60 FPS

## Compress events using delta encoding
func compress() -> void:
	# TODO: Implement delta compression for repeated events
	pass

## Calculate replay file size estimate
func estimate_size() -> int:
	return JSON.stringify({"events": events}).length()
