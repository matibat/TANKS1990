class_name EnemyAIController
extends Node
## Controls enemy tank AI behavior with state machine

enum AIState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK_BASE
}

## Current AI state
var current_state: AIState = AIState.IDLE

## Reference to controlled tank
var tank: Tank

## Target references
var player_tank: Tank = null
var base_position: Vector2 = Vector2.ZERO

## Patrol parameters
var patrol_direction: Vector2 = Vector2.ZERO
var patrol_timer: float = 0.0
var patrol_change_interval: float = 2.0

## Chase parameters
var chase_range: float = 300.0
var lose_chase_range: float = 400.0
var attack_range: float = 150.0

## Attack base parameters
var base_attack_chance: float = 0.3

## Shooting parameters
var shoot_timer: float = 0.0
var shoot_interval: float = 1.5

## Decision timer
var decision_timer: float = 0.0
var decision_interval: float = 0.5

func _init(controlled_tank: Tank = null) -> void:
	if controlled_tank:
		tank = controlled_tank

func _ready() -> void:
	set_physics_process(true)
	if tank:
		_initialize_patrol()

func _physics_process(delta: float) -> void:
	if not tank:
		return
	
	# Skip AI while spawning or dying
	if tank.current_state == Tank.State.DYING or tank.current_state == Tank.State.SPAWNING:
		return
	
	decision_timer += delta
	shoot_timer += delta
	patrol_timer += delta
	
	# Handle patrol direction changes independently of decision timer
	if current_state == AIState.PATROL and patrol_timer >= patrol_change_interval:
		_change_patrol_direction()
		patrol_timer = 0.0
	
	if decision_timer >= decision_interval:
		decision_timer = 0.0
		_evaluate_state()
		_execute_current_state()
	
	# Handle continuous actions (shooting) separately if needed
	_handle_continuous_actions(delta)

func _handle_continuous_actions(delta: float) -> void:
	# Handle shooting based on current state
	match current_state:
		AIState.PATROL:
			if shoot_timer >= shoot_interval and RandomProvider.chance(0.3):
				tank.try_fire()
				shoot_timer = 0.0
		AIState.CHASE:
			var distance = tank.global_position.distance_to(player_tank.global_position)
			if distance < attack_range and shoot_timer >= shoot_interval:
				tank.try_fire()
				shoot_timer = 0.0
		AIState.ATTACK_BASE:
			if shoot_timer >= shoot_interval:
				tank.try_fire()
				shoot_timer = 0.0

func _execute_current_state() -> void:
	match current_state:
		AIState.IDLE:
			_execute_idle()
		AIState.PATROL:
			_execute_patrol()
		AIState.CHASE:
			_execute_chase()
		AIState.ATTACK_BASE:
			_execute_attack_base()

func initialize(controlled_tank: Tank, player: Tank, base_pos: Vector2) -> void:
	tank = controlled_tank
	player_tank = player
	base_position = base_pos
	_initialize_patrol()
	_evaluate_state()

func _evaluate_state() -> void:
	if not player_tank or not is_instance_valid(player_tank):
		change_state(AIState.PATROL)
		return
	
	var distance_to_player = tank.global_position.distance_to(player_tank.global_position)
	
	match current_state:
		AIState.IDLE:
			if RandomProvider.chance(base_attack_chance):
				change_state(AIState.ATTACK_BASE)
			else:
				change_state(AIState.PATROL)
		
		AIState.PATROL:
			if distance_to_player < chase_range:
				change_state(AIState.CHASE)
			elif RandomProvider.chance(0.1):
				change_state(AIState.ATTACK_BASE)
		
		AIState.CHASE:
			if distance_to_player > lose_chase_range:
				change_state(AIState.PATROL)
		
		AIState.ATTACK_BASE:
			if distance_to_player < chase_range * 0.5:
				change_state(AIState.CHASE)
			elif tank.global_position.distance_to(base_position) < 100.0:
				change_state(AIState.PATROL)

func change_state(new_state: AIState) -> void:
	if current_state == new_state:
		return
	
	current_state = new_state
	_on_state_entered()

func _on_state_entered() -> void:
	match current_state:
		AIState.IDLE:
			tank.stop_movement()
		AIState.PATROL:
			_initialize_patrol()
		AIState.CHASE:
			pass
		AIState.ATTACK_BASE:
			pass

func _execute_idle() -> void:
	tank.stop_movement()

func _execute_patrol() -> void:
	# Move in current patrol direction
	var direction = _vector_to_direction(patrol_direction)
	tank.move_in_direction(direction)

func _execute_chase() -> void:
	if not player_tank or not is_instance_valid(player_tank):
		change_state(AIState.PATROL)
		return
	
	# Move toward player
	var direction_vec = (player_tank.global_position - tank.global_position).normalized()
	var direction = _vector_to_direction(_snap_to_4_directions(direction_vec))
	tank.move_in_direction(direction)

func _execute_attack_base() -> void:
	# Move toward base
	var direction_vec = (base_position - tank.global_position).normalized()
	var direction = _vector_to_direction(_snap_to_4_directions(direction_vec))
	tank.move_in_direction(direction)

func _initialize_patrol() -> void:
	_change_patrol_direction()
	patrol_timer = 0.0

func _change_patrol_direction() -> void:
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var index = RandomProvider.randi_range(0, directions.size() - 1)
	patrol_direction = directions[index]

func _snap_to_4_directions(direction: Vector2) -> Vector2:
	if abs(direction.x) > abs(direction.y):
		return Vector2.RIGHT if direction.x > 0 else Vector2.LEFT
	else:
		return Vector2.DOWN if direction.y > 0 else Vector2.UP

func _vector_to_direction(vec: Vector2) -> Tank.Direction:
	if vec == Vector2.UP:
		return Tank.Direction.UP
	elif vec == Vector2.DOWN:
		return Tank.Direction.DOWN
	elif vec == Vector2.LEFT:
		return Tank.Direction.LEFT
	elif vec == Vector2.RIGHT:
		return Tank.Direction.RIGHT
	else:
		return Tank.Direction.UP

func get_state_name() -> String:
	match current_state:
		AIState.IDLE: return "Idle"
		AIState.PATROL: return "Patrol"
		AIState.CHASE: return "Chase"
		AIState.ATTACK_BASE: return "AttackBase"
		_: return "Unknown"
