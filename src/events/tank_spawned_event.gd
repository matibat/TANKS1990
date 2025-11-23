class_name TankSpawnedEvent
extends GameEvent
## Event emitted when a tank spawns

var tank_id: int
var tank_type: String  # "player", "basic", "fast", "power", "armored"
var position: Vector2
var is_player: bool

func get_event_type() -> String:
	return "TankSpawned"

func to_dict() -> Dictionary:
	var base = super.to_dict()
	base["tank_id"] = tank_id
	base["tank_type"] = tank_type
	base["position"] = {"x": position.x, "y": position.y}
	base["is_player"] = is_player
	return base

static func from_dict(data: Dictionary) -> TankSpawnedEvent:
	var event = TankSpawnedEvent.new()
	event.frame = data.get("frame", 0)
	event.timestamp = data.get("timestamp", 0)
	event.tank_id = data.get("tank_id", 0)
	event.tank_type = data.get("tank_type", "basic")
	var pos = data.get("position", {"x": 0, "y": 0})
	event.position = Vector2(pos.x, pos.y)
	event.is_player = data.get("is_player", false)
	return event
