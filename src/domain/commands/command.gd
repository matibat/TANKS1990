class_name Command
extends RefCounted

## Command Base Class
## Base class for all commands (immutable inputs)
## Part of DDD architecture - pure domain logic with no Godot dependencies

var frame: int # Frame number when command was issued

## Check if command is valid
func is_valid() -> bool:
	return true # Override in subclasses

## Convert command to dictionary for serialization
func to_dict() -> Dictionary:
	return {"frame": frame}
