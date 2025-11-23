extends Node
## EventBus - Central event management system for gameplay events
## Supports recording, playback, and network synchronization

# Event recording state
var is_recording: bool = false
var is_replaying: bool = false
var recorded_events: Array[GameEvent] = []
var current_frame: int = 0
var start_time: int = 0

# Event listeners organized by type
var listeners: Dictionary = {}  # event_type -> Array[Callable]

# Replay state
var replay_data: ReplayData = null
var replay_index: int = 0

# Random seed for determinism
var game_seed: int = 0

# Signals for system events
signal recording_started()
signal recording_stopped(event_count: int)
signal replay_started()
signal replay_finished()
signal replay_progress(current_frame: int, total_frames: int)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	start_time = Time.get_ticks_msec()

func _physics_process(_delta: float) -> void:
	if is_replaying:
		_process_replay_events()
	
	current_frame += 1

## Emit and record game event
func emit_game_event(event: GameEvent) -> void:
	event.frame = current_frame
	event.timestamp = Time.get_ticks_msec() - start_time
	
	# Record if recording enabled
	if is_recording:
		recorded_events.append(event)
	
	# Notify listeners
	_notify_listeners(event)
	
	# Debug logging
	_log_event(event)

## Subscribe to specific event type
func subscribe(event_type: String, callback: Callable) -> void:
	if not listeners.has(event_type):
		listeners[event_type] = []
	
	if not listeners[event_type].has(callback):
		listeners[event_type].append(callback)

## Unsubscribe from specific event type
func unsubscribe(event_type: String, callback: Callable) -> void:
	if listeners.has(event_type):
		listeners[event_type].erase(callback)

## Unsubscribe all listeners for event type
func unsubscribe_all(event_type: String) -> void:
	listeners.erase(event_type)

## Clear all listeners
func clear_all_listeners() -> void:
	listeners.clear()

## Start recording gameplay
func start_recording(random_seed: int = -1) -> void:
	recorded_events.clear()
	current_frame = 0
	start_time = Time.get_ticks_msec()
	is_recording = true
	
	# Set deterministic seed
	if random_seed == -1:
		game_seed = Time.get_ticks_msec() % 1000000
	else:
		game_seed = random_seed
	
	seed(game_seed)
	recording_started.emit()

## Stop recording and return replay data
func stop_recording() -> ReplayData:
	is_recording = false
	
	var data = ReplayData.new()
	data.game_seed = game_seed
	data.total_frames = current_frame
	data.duration_seconds = (Time.get_ticks_msec() - start_time) / 1000.0
	
	# Convert events to dictionaries
	for event in recorded_events:
		data.add_event(event)
	
	recording_stopped.emit(recorded_events.size())
	return data

## Start replay from replay data
func start_replay(data: ReplayData) -> void:
	replay_data = data
	replay_index = 0
	current_frame = 0
	is_replaying = true
	
	# Set deterministic seed
	game_seed = data.game_seed
	seed(game_seed)
	
	replay_started.emit()

## Stop current replay
func stop_replay() -> void:
	is_replaying = false
	replay_data = null
	replay_index = 0
	replay_finished.emit()

## Pause replay
func pause_replay() -> void:
	set_physics_process(false)

## Resume replay
func resume_replay() -> void:
	set_physics_process(true)

## Process replay events for current frame
func _process_replay_events() -> void:
	if replay_data == null or replay_index >= replay_data.events.size():
		stop_replay()
		return
	
	# Process all events for current frame
	while replay_index < replay_data.events.size():
		var event_dict = replay_data.events[replay_index]
		if event_dict.get("frame", 0) > current_frame:
			break
		
		# Reconstruct and emit event
		var event = _reconstruct_event(event_dict)
		if event:
			_notify_listeners(event)
		
		replay_index += 1
	
	# Emit progress
	if replay_data.total_frames > 0:
		replay_progress.emit(current_frame, replay_data.total_frames)

## Notify all listeners of event
func _notify_listeners(event: GameEvent) -> void:
	var event_type = event.get_event_type()
	if listeners.has(event_type):
		for callback in listeners[event_type]:
			callback.call(event)

## Reconstruct event from dictionary
func _reconstruct_event(data: Dictionary) -> GameEvent:
	var event_type = data.get("type", "")
	
	# Dynamically load event class based on type
	match event_type:
		"Input":
			return PlayerInputEvent.from_dict(data)
		"TankSpawned":
			return TankSpawnedEvent.from_dict(data)
		"TankDestroyed":
			return TankDestroyedEvent.from_dict(data)
		"BulletFired":
			return BulletFiredEvent.from_dict(data)
		"Collision":
			return CollisionEvent.from_dict(data)
		"PowerUpSpawned":
			return PowerUpSpawnedEvent.from_dict(data)
		"PowerUpCollected":
			return PowerUpCollectedEvent.from_dict(data)
		_:
			return GameEvent.from_dict(data)

## Debug logging for events
func _log_event(event: GameEvent) -> void:
	if OS.is_debug_build() and OS.has_feature("editor"):
		print("[EventBus] Frame %d: %s" % [event.frame, event.get_event_type()])
