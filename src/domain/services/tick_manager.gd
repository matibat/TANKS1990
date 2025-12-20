extends RefCounted
class_name TickManager

## Tick Manager Service
## 
## Decouples game logic ticks from rendering frames, enabling fixed-rate 
## game updates independent of variable frame rates.
##
## Key Concepts:
## - Ticks Per Second (TPS): How many logic updates per second
## - Fixed Delta: Time between ticks (1.0 / TPS)
## - Accumulator: Accumulates frame time until a tick is ready
## - Tick Progress: Interpolation factor for smooth rendering (0.0-1.0)
##
## Usage:
##   var tick_manager = TickManager.new()
##   tick_manager.set_ticks_per_second(10)  # 10 logic updates per second
##   
##   func _physics_process(delta):
##       while tick_manager.should_process_tick(delta):
##           # Process one tick of game logic
##           game_loop.process_frame(commands)
##       
##       # Use tick_progress for interpolation
##       var progress = tick_manager.get_tick_progress()
##       tank_visual.position = lerp(old_pos, new_pos, progress)

const DEFAULT_TPS = 60
const EPSILON = 0.0001 # Tolerance for floating point comparisons

var _ticks_per_second: int = DEFAULT_TPS
var _fixed_delta: float = 1.0 / DEFAULT_TPS
var _accumulator: float = 0.0

func _init():
	set_ticks_per_second(DEFAULT_TPS)

## Set the target ticks per second for game logic
func set_ticks_per_second(tps: int) -> void:
	assert(tps > 0, "Ticks per second must be positive")
	_ticks_per_second = tps
	_fixed_delta = 1.0 / float(tps)

## Get the fixed time step between ticks
func get_fixed_delta() -> float:
	return _fixed_delta

## Check if enough time has accumulated for a tick
## 
## On the first call per frame, pass the frame delta.
## On subsequent calls (in a while loop), pass 0.0 to check accumulated time.
##
## Usage pattern 1 (single tick per call):
##   if tick_manager.should_process_tick(delta):
##       process_one_tick()
##
## Usage pattern 2 (multiple ticks if frame is long):
##   tick_manager.accumulate(delta)
##   while tick_manager.should_process_tick(0.0):
##       process_one_tick()
##
## Returns true if a tick should be processed, false otherwise.
func should_process_tick(delta: float) -> bool:
	if delta > 0.0:
		_accumulator += delta
	
	# Use epsilon tolerance for floating point comparison
	if _accumulator >= _fixed_delta - EPSILON:
		_accumulator -= _fixed_delta
		return true
	
	return false

## Get interpolation factor for smooth rendering between ticks
##
## Returns a value from 0.0 to 1.0 representing how far we are
## between the last tick and the next tick.
##
## Usage:
##   var progress = tick_manager.get_tick_progress()
##   visual_position = lerp(last_tick_pos, next_tick_pos, progress)
func get_tick_progress() -> float:
	return _accumulator / _fixed_delta
