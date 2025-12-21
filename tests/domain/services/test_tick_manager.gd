extends GutTest

const TickManager = preload("res://src/domain/services/tick_manager.gd")

var tick_manager: TickManager

func before_each():
	tick_manager = TickManager.new()

func after_each():
	tick_manager = null

func test_given_60fps_when_10tps_then_updates_every_6_frames():
	# Given: 60 FPS render rate, 10 TPS logic rate
	tick_manager.set_ticks_per_second(10)
	
	# When: Process 6 frames at 60 FPS (1/60 second each)
	# Call should_process_tick once per frame, accumulating delta
	var tick_count = 0
	for i in range(6):
		if tick_manager.should_process_tick(1.0 / 60.0):
			tick_count += 1
	
	# Then: Exactly 1 tick should occur (after 6 frames = 0.1 seconds)
	assert_eq(tick_count, 1, "Should process exactly 1 tick per 6 frames at 60 FPS / 10 TPS")

func test_given_accumulator_when_tick_ready_then_processes_tick():
	# Given: 10 TPS (0.1 second per tick)
	tick_manager.set_ticks_per_second(10)
	
	# When: Accumulate exactly one tick's worth of time
	var should_tick1 = tick_manager.should_process_tick(0.05) # First half
	var should_tick2 = tick_manager.should_process_tick(0.05) # Second half
	
	# Then: First call returns false, second returns true
	assert_false(should_tick1, "Should not tick after 0.05s")
	assert_true(should_tick2, "Should tick after accumulating 0.1s total")

func test_given_variable_delta_when_accumulating_then_stable_ticks():
	# Given: 10 TPS (0.1 second per tick), variable frame times
	tick_manager.set_ticks_per_second(10)
	
	# When: Process variable frame times that sum to 1.0 second
	var deltas = [0.016, 0.020, 0.014, 0.018, 0.016, 0.019] # Simulate 60 FPS with jitter
	var tick_count = 0
	var total_time = 0.0
	
	for delta in deltas:
		total_time += delta
		if tick_manager.should_process_tick(delta):
			tick_count += 1
	
	# Continue until 1.0 second total
	while total_time < 1.0:
		var delta = 0.016
		total_time += delta
		if tick_manager.should_process_tick(delta):
			tick_count += 1
	
	# Then: Should process exactly 10 ticks in 1.0 second (10 TPS)
	assert_eq(tick_count, 10, "Should process exactly 10 ticks per second regardless of frame jitter")

func test_given_tick_interval_when_get_fixed_delta_then_returns_correct_value():
	# Given: 10 TPS
	tick_manager.set_ticks_per_second(10)
	
	# When: Get fixed delta
	var fixed_delta = tick_manager.get_fixed_delta()
	
	# Then: Should be 0.1 seconds
	assert_almost_eq(fixed_delta, 0.1, 0.001, "Fixed delta should be 0.1s for 10 TPS")

func test_given_20_tps_when_get_fixed_delta_then_returns_0_05():
	# Given: 20 TPS
	tick_manager.set_ticks_per_second(20)
	
	# When: Get fixed delta
	var fixed_delta = tick_manager.get_fixed_delta()
	
	# Then: Should be 0.05 seconds
	assert_almost_eq(fixed_delta, 0.05, 0.001, "Fixed delta should be 0.05s for 20 TPS")

func test_given_multiple_ticks_accumulated_when_should_process_then_returns_true_multiple_times():
	# Given: 10 TPS, a long frame time
	tick_manager.set_ticks_per_second(10)
	
	# When: Process a frame that spans 3 ticks (0.3 seconds)
	var tick_count = 0
	# Pass delta once to accumulate
	if tick_manager.should_process_tick(0.3):
		tick_count += 1
	# Then consume remaining ticks
	while tick_manager.should_process_tick(0.0):
		tick_count += 1
		if tick_count > 10: # Safety break
			break
	
	# Then: Should process 3 ticks
	assert_eq(tick_count, 3, "Should process 3 ticks for 0.3s frame at 10 TPS")

func test_given_tick_manager_when_get_tick_progress_then_returns_interpolation_factor():
	# Given: 10 TPS
	tick_manager.set_ticks_per_second(10)
	
	# When: Accumulate half a tick
	tick_manager.should_process_tick(0.05)
	var progress = tick_manager.get_tick_progress()
	
	# Then: Progress should be 0.5 (halfway to next tick)
	assert_almost_eq(progress, 0.5, 0.1, "Tick progress should be 0.5 halfway through tick interval")

func test_given_accumulator_exceeds_tick_when_get_tick_progress_then_clamps_to_one():
	# Given: 10 TPS
	tick_manager.set_ticks_per_second(10)

	# When: Accumulate more than one tick but only consume one
	tick_manager.should_process_tick(0.25)
	var progress = tick_manager.get_tick_progress()

	# Then: Progress should clamp to 1.0
	assert_almost_eq(progress, 1.0, 0.001, "Tick progress should clamp to 1.0 when over-accumulated")

func test_given_new_tick_manager_when_created_then_defaults_to_60_tps():
	# Given: New tick manager
	var new_manager = TickManager.new()
	
	# When: Check default TPS
	var fixed_delta = new_manager.get_fixed_delta()
	
	# Then: Should default to 60 TPS (0.0166... seconds)
	assert_almost_eq(fixed_delta, 1.0 / 60.0, 0.001, "Should default to 60 TPS")
