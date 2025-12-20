extends GutTest
## BDD Test: 3D Shooting Mechanics - Test-First BDD
##
## ROOT CAUSE: Bullets destroyed immediately in physics callback
## EXPECTED: Test will FAIL showing bullets disappear instantly

const Bullet3D = preload("res://src/entities/bullet3d.gd")
const BulletManager3D = preload("res://src/managers/bullet_manager_3d.gd")
const BulletFiredEvent = preload("res://src/events/bullet_fired_event.gd")

var bullet_manager: BulletManager3D

func before_each():
	bullet_manager = BulletManager3D.new()
	add_child(bullet_manager)
	await get_tree().process_frame

func after_each():
	if bullet_manager:
		bullet_manager.queue_free()

func test_bullet_survives_initial_spawn_without_immediate_destruction():
	"""
	BDD: GIVEN bullet fired WHEN physics frames pass THEN bullet still visible
	EXPECTED FAIL: Bullet destroyed immediately (hits owner tank)
	"""
	# Arrange & Act
	var event = BulletFiredEvent.new()
	event.tank_id = 1
	event.position = Vector3(5.0, 0, 5.0)
	event.direction = Vector3(0, 0, -1)
	event.bullet_level = 1
	event.is_player_bullet = true
	
	EventBus.emit_game_event(event)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var bullets = _get_active_bullets()
	gut.p("Bullets spawned: %d" % bullets.size())
	assert_gt(bullets.size(), 0, "Bullet should spawn")
	
	if bullets.size() > 0:
		var bullet = bullets[0]
		var initial_pos = bullet.global_position
		gut.p("Initial: pos=%s visible=%s active=%s" % [initial_pos, bullet.visible, bullet.is_active])
		
		# Wait 5 physics frames
		for i in range(5):
			await get_tree().physics_frame
			if is_instance_valid(bullet):
				gut.p("Frame %d: pos=%s visible=%s active=%s" % [
					i, bullet.global_position, bullet.visible, bullet.is_active
				])
		
		# Assert
		assert_true(is_instance_valid(bullet), "Bullet should still exist")
		if is_instance_valid(bullet):
			assert_true(bullet.visible, "FAIL: Bullet invisible (destroyed)")
			assert_true(bullet.is_active, "FAIL: Bullet is_active=false")
			var distance = initial_pos.distance_to(bullet.global_position)
			assert_gt(distance, 0.01, "Bullet should have moved")

func _get_active_bullets() -> Array:
	var bullets: Array = []
	if bullet_manager:
		for child in bullet_manager.get_children():
			if child is Bullet3D or (child is Area3D and child.has_method("initialize")):
				if child.visible and child.process_mode != Node.PROCESS_MODE_DISABLED:
					bullets.append(child)
	return bullets

# ========================================
# CRITICAL TEST: Bullet Visibility
# ========================================

func test_bullet_has_visible_mesh_at_runtime():
	"""
	BDD: GIVEN bullet scene is instantiated at runtime
	     WHEN bullet is spawned
	     THEN MeshInstance3D child has a valid mesh assigned
	
	EXPECTED: FAIL - mesh_loader is @tool and doesn't run at runtime
	ROOT CAUSE: mesh = null at runtime, bullets are invisible
	"""
	# Arrange: Fire bullet via EventBus (simulates real gameplay)
	var event = BulletFiredEvent.new()
	event.tank_id = 1
	event.position = Vector3(5.0, 0, 5.0)
	event.direction = Vector3(0, 0, -1)
	event.bullet_level = 1
	event.is_player_bullet = true
	
	# Act: Trigger bullet spawn
	EventBus.emit_game_event(event)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# Assert: Find spawned bullet
	var bullets = _get_active_bullets()
	gut.p("Found %d bullets" % bullets.size())
	assert_gt(bullets.size(), 0, "At least one bullet should be spawned")
	
	if bullets.size() > 0:
		var bullet = bullets[0]
		gut.p("Bullet visible: %s" % bullet.visible)
		gut.p("Bullet process_mode: %d" % bullet.process_mode)
		
		# Check visibility
		assert_true(bullet.visible, "Bullet should be visible")
		
		# Check MeshInstance3D exists
		var mesh_instance = bullet.get_node_or_null("MeshInstance3D")
		gut.p("MeshInstance3D found: %s" % (mesh_instance != null))
		assert_not_null(mesh_instance, "Bullet should have MeshInstance3D child")
		
		# CRITICAL: Check mesh is assigned (EXPECTED TO FAIL)
		if mesh_instance:
			var mesh = mesh_instance.mesh
			gut.p("Mesh assigned: %s" % (mesh != null))
			if mesh:
				gut.p("Mesh type: %s" % mesh.get_class())
				var surface_count = mesh.get_surface_count()
				gut.p("Mesh surface count: %d" % surface_count)
			
			assert_not_null(mesh, 
				"EXPECTED FAILURE: MeshInstance3D.mesh is NULL at runtime because @tool script doesn't run")
			
			if mesh:
				var surface_count = mesh.get_surface_count()
				assert_gt(surface_count, 0, "Mesh should have at least one surface")
