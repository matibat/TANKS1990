class_name TankStats
extends RefCounted

## TankStats Value Object
## Represents tank capabilities and attributes
## Part of DDD architecture - pure domain logic with no Godot dependencies

var speed: int # Tiles per frame
var fire_rate: int # Frames between shots (cooldown)
var armor: int # Health points
var bullet_speed: int # Tiles per frame

## Static factory method to create custom stats
static func create(p_speed: int, p_fire_rate: int, p_armor: int, p_bullet_speed: int):
	var s = new()
	s.speed = max(1, p_speed)
	s.fire_rate = max(1, p_fire_rate)
	s.armor = max(0, p_armor)
	s.bullet_speed = max(1, p_bullet_speed)
	return s

## Static factory method for player default stats
static func player_default():
	var s = new()
	s.speed = 2 # speed: moderate
	s.fire_rate = 6 # fire_rate: snappier at 10 TPS (~0.6s)
	s.armor = 1 # armor: 1 hit point
	s.bullet_speed = 2 # bullet_speed: discrete but smooth when interpolated
	return s

## Static factory method for basic enemy stats
static func enemy_basic():
	var s = new()
	s.speed = 1 # speed: slow
	s.fire_rate = 10 # fire_rate: slower than player
	s.armor = 1 # armor: 1 hit point
	s.bullet_speed = 2 # bullet_speed: slower than player
	return s

## Static factory method for fast enemy stats
static func enemy_fast():
	var s = new()
	s.speed = 3 # speed: fast
	s.fire_rate = 8 # fire_rate: moderate at 10 TPS
	s.armor = 1 # armor: 1 hit point
	s.bullet_speed = 3 # bullet_speed: fast but readable
	return s

## Static factory method for power enemy stats
static func enemy_power():
	var s = new()
	s.speed = 2 # speed: normal
	s.fire_rate = 7 # fire_rate: fast shooting at 10 TPS
	s.armor = 1 # armor: 1 hit point
	s.bullet_speed = 3 # bullet_speed: fast
	return s

## Static factory method for armored enemy stats
static func enemy_armored():
	var s = new()
	s.speed = 1 # speed: slow
	s.fire_rate = 14 # fire_rate: very slow at 10 TPS
	s.armor = 4 # armor: 4 hit points
	s.bullet_speed = 2 # bullet_speed: slow
	return s

## String representation for debugging
func _to_string() -> String:
	return "TankStats(speed:%d, fire_rate:%d, armor:%d, bullet_speed:%d)" % [speed, fire_rate, armor, bullet_speed]
