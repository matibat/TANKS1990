class_name Tank
extends CharacterBody2D
## Base tank entity with movement, shooting, and health

signal health_changed(new_health: int, max_health: int)
signal died()
signal state_changed(new_state: State)

enum State { IDLE, MOVING, SHOOTING, DYING, INVULNERABLE, SPAWNING }
enum Direction { UP, DOWN, LEFT, RIGHT }
enum TankType { PLAYER, BASIC, FAST, POWER, ARMORED }

# Configuration
@export var tank_type: TankType = TankType.PLAYER
@export var base_speed: float = 100.0
@export var max_health: int = 1
@export var fire_cooldown_time: float = 0.5
@export var invulnerability_duration: float = 3.0

# State
var current_state: State = State.SPAWNING
var facing_direction: Direction = Direction.UP
var current_health: int
var level: int = 0  # 0-3 for player upgrades
var is_player: bool = false
var tank_id: int = 0

# Internal
var fire_cooldown: float = 0.0
var invulnerability_timer: float = 0.0
var spawn_timer: float = 0.0
const SPAWN_DURATION: float = 2.0
const TILE_SIZE: int = 16

# Visual
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

func _ready() -> void:
	current_health = max_health
	is_player = (tank_type == TankType.PLAYER)
	_setup_collision()
	_change_state(State.SPAWNING)

func _setup_collision() -> void:
	# Tank collision is 16x16 (1 tile)
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(TILE_SIZE, TILE_SIZE)
		collision_shape.shape = rect
		add_child(collision_shape)

func _physics_process(delta: float) -> void:
	# Update timers
	if fire_cooldown > 0:
		fire_cooldown -= delta
	
	if invulnerability_timer > 0:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0:
			_end_invulnerability()
	
	if spawn_timer > 0:
		spawn_timer -= delta
		if spawn_timer <= 0:
			_complete_spawn()
	
	# Process movement
	if current_state == State.MOVING or current_state == State.IDLE:
		_process_movement(delta)

func _process_movement(_delta: float) -> void:
	# Move and slide using velocity
	var collision = move_and_slide()
	
	# Emit event if actually moved
	if velocity.length() > 0 and collision:
		_emit_tank_moved_event()

## Set movement direction and velocity
func move_in_direction(direction: Direction) -> void:
	if current_state == State.DYING or current_state == State.SPAWNING:
		return
	
	facing_direction = direction
	velocity = _direction_to_vector(direction) * _get_current_speed()
	
	if current_state != State.MOVING:
		_change_state(State.MOVING)
	
	_update_sprite_rotation()

## Stop tank movement
func stop_movement() -> void:
	velocity = Vector2.ZERO
	if current_state == State.MOVING:
		_change_state(State.IDLE)

## Attempt to fire bullet
func try_fire() -> bool:
	if fire_cooldown > 0:
		return false
	
	if current_state == State.DYING or current_state == State.SPAWNING:
		return false
	
	fire_cooldown = fire_cooldown_time
	_emit_bullet_fired_event()
	return true

## Take damage from bullet or collision
func take_damage(amount: int = 1) -> void:
	if current_state == State.INVULNERABLE or current_state == State.SPAWNING:
		return
	
	if current_state == State.DYING:
		return
	
	current_health -= amount
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		die()

## Handle tank death
func die() -> void:
	_change_state(State.DYING)
	velocity = Vector2.ZERO
	
	# Emit death event
	var event = TankDestroyedEvent.new()
	event.tank_id = tank_id
	event.was_player = is_player
	event.position = global_position
	event.destroyed_by_id = -1  # Will be set by damage dealer
	event.score_value = _get_score_value()
	EventBus.emit_game_event(event)
	
	died.emit()
	
	# Play death animation then queue_free
	if animation_player and animation_player.has_animation("die"):
		animation_player.play("die")
		await animation_player.animation_finished
	
	queue_free()

## Activate invulnerability shield
func activate_invulnerability(duration: float = 0.0) -> void:
	if duration > 0:
		invulnerability_duration = duration
	
	invulnerability_timer = invulnerability_duration
	_change_state(State.INVULNERABLE)
	
	# Visual feedback (shield effect)
	modulate = Color(1, 1, 1, 0.7)

## Upgrade player tank level (0-3)
func upgrade_level() -> void:
	if not is_player:
		return
	
	level = mini(level + 1, 3)
	_apply_level_bonuses()

func _apply_level_bonuses() -> void:
	match level:
		1:
			fire_cooldown_time = 0.4  # Faster shooting
		2:
			fire_cooldown_time = 0.3
			max_health = 2  # Can take 1 hit
		3:
			fire_cooldown_time = 0.25
			max_health = 2

func _complete_spawn() -> void:
	_change_state(State.IDLE)
	activate_invulnerability(invulnerability_duration)

func _end_invulnerability() -> void:
	if current_state == State.INVULNERABLE:
		_change_state(State.IDLE)
	modulate = Color.WHITE

func _change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	
	current_state = new_state
	state_changed.emit(new_state)
	
	# Handle state entry
	match new_state:
		State.SPAWNING:
			spawn_timer = SPAWN_DURATION
			modulate = Color(1, 1, 1, 0.5)
		State.IDLE:
			velocity = Vector2.ZERO
		State.DYING:
			set_physics_process(false)

func _direction_to_vector(direction: Direction) -> Vector2:
	match direction:
		Direction.UP:
			return Vector2.UP
		Direction.DOWN:
			return Vector2.DOWN
		Direction.LEFT:
			return Vector2.LEFT
		Direction.RIGHT:
			return Vector2.RIGHT
	return Vector2.ZERO

func _get_current_speed() -> float:
	var speed = base_speed
	
	# Tank type modifiers
	match tank_type:
		TankType.FAST:
			speed *= 1.5
		TankType.POWER:
			speed *= 0.8
	
	return speed

func _get_score_value() -> int:
	match tank_type:
		TankType.BASIC:
			return 100
		TankType.FAST:
			return 200
		TankType.POWER:
			return 300
		TankType.ARMORED:
			return 400
		TankType.PLAYER:
			return 0
	return 0

func _update_sprite_rotation() -> void:
	if not sprite:
		return
	
	match facing_direction:
		Direction.UP:
			sprite.rotation_degrees = 0
		Direction.RIGHT:
			sprite.rotation_degrees = 90
		Direction.DOWN:
			sprite.rotation_degrees = 180
		Direction.LEFT:
			sprite.rotation_degrees = 270

func _emit_tank_moved_event() -> void:
	var event = TankMovedEvent.new()
	event.tank_id = tank_id
	event.position = global_position
	event.direction = _direction_to_vector(facing_direction)
	event.velocity = velocity
	EventBus.emit_game_event(event)

func _emit_bullet_fired_event() -> void:
	var event = BulletFiredEvent.new()
	event.tank_id = tank_id
	event.bullet_id = 0  # Will be set by BulletManager
	event.position = global_position
	event.direction = _direction_to_vector(facing_direction)
	event.bullet_level = level
	EventBus.emit_game_event(event)
