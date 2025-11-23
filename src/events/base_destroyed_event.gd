class_name BaseDestroyedEvent
extends GameEvent
## Event emitted when the base (Eagle) is destroyed

var position: Vector2
var destroyed_by_id: int = -1  # Tank ID that destroyed the base

func get_event_type() -> String:
	return "BaseDestroyed"

func to_dict() -> Dictionary:
	var base = super.to_dict()
	base["position"] = {"x": position.x, "y": position.y}
	base["destroyed_by_id"] = destroyed_by_id
	return base

static func from_dict(data: Dictionary) -> BaseDestroyedEvent:
	var event = BaseDestroyedEvent.new()
	event.frame = data.get("frame", 0)
	event.timestamp = data.get("timestamp", 0)
	
	var pos = data.get("position", {"x": 0, "y": 0})
	event.position = Vector2(pos.x, pos.y)
	event.destroyed_by_id = data.get("destroyed_by_id", -1)
	
	return event
