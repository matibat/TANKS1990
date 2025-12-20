class_name DomainEvent
extends RefCounted

## DomainEvent Base Class
## Base class for all domain events (immutable outputs)
## Part of DDD architecture - pure domain logic with no Godot dependencies

var frame: int # Frame number when event occurred
var timestamp: int # Unix timestamp when event occurred

## Convert event to dictionary for serialization
func to_dict() -> Dictionary:
	return {
		"frame": frame,
		"timestamp": timestamp
	}
