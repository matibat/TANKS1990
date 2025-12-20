class_name TankDestroyedEvent
extends GameEvent
## Event emitted when a tank is destroyed

var tank_id: int
var tank_type: String = ""  # Tank type (Basic, Fast, Power, Armored, Player)
var destroyed_by_id: int  # ID of tank/bullet that caused destruction
var position: Variant  # Vector2 (2D) or Vector3 (3D)
var was_player: bool
var score_value: int

func get_event_type() -> String:
	return "TankDestroyed"

func to_dict() -> Dictionary:
	var base = super.to_dict()
	base["tank_id"] = tank_id
	base["tank_type"] = tank_type
	base["destroyed_by_id"] = destroyed_by_id
	base["position"] = {"x": position.x, "y": position.y}
	base["was_player"] = was_player
	base["score_value"] = score_value
	return base

static func from_dict(data: Dictionary) -> TankDestroyedEvent:
	var event = TankDestroyedEvent.new()
	event.frame = data.get("frame", 0)
	event.timestamp = data.get("timestamp", 0)
	event.tank_id = data.get("tank_id", 0)
	event.tank_type = data.get("tank_type", "")
	event.destroyed_by_id = data.get("destroyed_by_id", -1)
	var pos = data.get("position", {"x": 0, "y": 0})
	event.position = Vector2(pos.x, pos.y)
	event.was_player = data.get("was_player", false)
	event.score_value = data.get("score_value", 0)
	return event
