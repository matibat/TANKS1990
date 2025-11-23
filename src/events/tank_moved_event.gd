class_name TankMovedEvent
extends GameEvent
## Event emitted when a tank moves (for replay validation)

var tank_id: int
var position: Vector2
var direction: Vector2
var velocity: Vector2

func get_event_type() -> String:
	return "TankMoved"

func to_dict() -> Dictionary:
	var base = super.to_dict()
	base["tank_id"] = tank_id
	base["position"] = {"x": position.x, "y": position.y}
	base["direction"] = {"x": direction.x, "y": direction.y}
	base["velocity"] = {"x": velocity.x, "y": velocity.y}
	return base

static func from_dict(data: Dictionary) -> TankMovedEvent:
	var event = TankMovedEvent.new()
	event.frame = data.get("frame", 0)
	event.timestamp = data.get("timestamp", 0)
	event.tank_id = data.get("tank_id", 0)
	var pos = data.get("position", {"x": 0, "y": 0})
	event.position = Vector2(pos.x, pos.y)
	var dir = data.get("direction", {"x": 0, "y": 0})
	event.direction = Vector2(dir.x, dir.y)
	var vel = data.get("velocity", {"x": 0, "y": 0})
	event.velocity = Vector2(vel.x, vel.y)
	return event
