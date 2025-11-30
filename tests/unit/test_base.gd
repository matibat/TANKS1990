extends GutTest
## BDD Test Suite: Base Entity (Eagle)
## Tests base health, destruction, and protection

var base: Base
var event_bus: Node

func before_each():
	event_bus = get_node("/root/EventBus")
	event_bus.recorded_events.clear()
	event_bus.current_frame = 0
	base = Base.new()
	add_child_autofree(base)
	await wait_physics_frames(1) # Wait for _ready() to run

## ============================================================================
## Epic: Base Initialization
## ============================================================================

func test_given_base_created_when_initialized_then_has_default_health():
	# Given: Base entity created
	# When: Initialized
	# Then: Has default health value
	assert_eq(base.health, 1, "Base should have 1 health by default")
	assert_false(base.is_destroyed, "Base should not be destroyed initially")

func test_given_base_created_when_initialized_then_positioned_correctly():
	# Given: Base entity
	# When: Positioned at map bottom
	# Then: Position is at bottom center of tile map (13, 25)
	var expected_x = 13 * 16 + 8  # Tile center
	var expected_y = 25 * 16 + 8  # Tile center
	assert_eq(base.position, Vector2(expected_x, expected_y), "Base should be at tile (13, 25) center")

func test_given_base_created_when_initialized_then_has_collision_shape():
	# Given: Base entity created
	# When: Checking collision setup
	var collision_shape = base.get_node_or_null("CollisionShape2D")
	
	# Then: Has collision shape for detection
	assert_not_null(collision_shape, "Base should have collision shape")

## ============================================================================
## Epic: Base Damage & Destruction
## ============================================================================

func test_given_base_intact_when_player_bullet_hits_then_bullet_destroyed_no_damage():
	# Given: Base with full health and player bullet
	var initial_health = base.health
	var bullet = Bullet.new()
	bullet.owner_type = Bullet.OwnerType.PLAYER
	add_child_autofree(bullet)
	await get_tree().process_frame
	
	# When: Player bullet collides with base
	base._on_area_entered(bullet)
	
	# Then: Bullet is destroyed but base takes no damage
	assert_false(bullet.is_active, "Player bullet should be destroyed on base hit")
	assert_eq(base.health, initial_health, "Base should not take damage from player bullets")
	assert_false(base.is_destroyed, "Base should not be destroyed by player bullets")

func test_given_player_tank_when_fires_at_base_then_base_not_damaged():
	# Given: Player tank and base with bullet manager
	var player_tank = Tank.new()
	player_tank.tank_type = Tank.TankType.PLAYER
	player_tank.is_player = true
	player_tank.position = Vector2(208, 300)
	player_tank.facing_direction = Tank.Direction.DOWN
	add_child_autofree(player_tank)
	
	var bullet_manager = BulletManager.new()
	add_child_autofree(bullet_manager)
	
	var initial_health = base.health
	await get_tree().process_frame
	
	# When: Player tank fires at base
	player_tank.try_fire()
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Get spawned bullet and verify it's marked as player bullet
	var bullets = get_tree().get_nodes_in_group("bullets")
	if bullets.size() > 0:
		var bullet = bullets[0] as Bullet
		assert_eq(bullet.owner_type, Bullet.OwnerType.PLAYER, "Bullet should be marked as player bullet")
		
		# Simulate bullet hitting base
		base._on_area_entered(bullet)
	
	# Then: Base should not be damaged
	assert_eq(base.health, initial_health, "Base should not take damage from player tank bullets")

func test_given_base_intact_when_enemy_bullet_hits_then_bullet_destroyed_and_damage_taken():
	# Given: Base with full health and enemy bullet
	var initial_health = base.health
	var bullet = Bullet.new()
	bullet.owner_type = Bullet.OwnerType.ENEMY
	add_child_autofree(bullet)
	await get_tree().process_frame
	
	# When: Enemy bullet collides with base
	base._on_area_entered(bullet)
	
	# Then: Bullet is destroyed AND base takes damage
	assert_false(bullet.is_active, "Enemy bullet should be destroyed on base hit")
	assert_eq(base.health, initial_health - 1, "Base should take damage from enemy bullets")

func test_given_base_intact_when_takes_damage_then_health_decreases():
	# Given: Base with full health
	var initial_health = base.health
	
	# When: Base takes damage
	base.take_damage(1)
	
	# Then: Health decreases
	assert_eq(base.health, initial_health - 1, "Health should decrease by damage amount")

func test_given_base_health_zero_when_damaged_then_marks_destroyed():
	# Given: Base with 1 health
	base.health = 1
	
	# When: Takes fatal damage
	base.take_damage(1)
	
	# Then: Marked as destroyed
	assert_true(base.is_destroyed, "Base should be marked as destroyed")
	assert_eq(base.health, 0, "Health should be zero")

func test_given_base_destroyed_when_takes_more_damage_then_ignores_damage():
	# Given: Base already destroyed
	base.health = 1
	base.take_damage(1)
	assert_true(base.is_destroyed)
	
	# When: Takes additional damage
	base.take_damage(1)
	
	# Then: Health stays at zero
	assert_eq(base.health, 0, "Health should remain at zero")

func test_given_base_destroyed_when_event_emitted_then_signal_fired():
	# Given: Base about to be destroyed
	var signal_watcher = watch_signals(base)
	base.health = 1
	
	# When: Takes fatal damage
	base.take_damage(1)
	
	# Then: destroyed signal emitted
	assert_signal_emitted(base, "destroyed", "Should emit destroyed signal")

func test_given_base_destroyed_when_event_emitted_then_creates_event():
	# Given: Base about to be destroyed
	event_bus.start_recording()
	base.health = 1
	
	# When: Takes fatal damage
	base.take_damage(1)
	await wait_physics_frames(1)
	
	# Then: BaseDestroyedEvent created
	var events = event_bus.recorded_events.filter(func(e): return e.get_event_type() == "BaseDestroyed")
	assert_gt(events.size(), 0, "Should create BaseDestroyedEvent")

## ============================================================================
## Epic: Base Collision Detection
## ============================================================================

func test_given_bullet_hits_base_when_collision_detected_then_takes_damage():
	# Given: Base with collision detection
	var bullet = Bullet.new()
	bullet.position = base.position
	bullet.direction = Vector2.UP
	bullet.owner_type = Bullet.OwnerType.ENEMY
	add_child_autofree(bullet)
	
	# When: Bullet overlaps base area
	base._on_area_entered(bullet)
	
	# Then: Base takes damage
	assert_eq(base.health, 0, "Base should take damage from bullet")

func test_given_enemy_tank_hits_base_when_collision_detected_then_takes_damage():
	# Given: Base with collision detection
	var enemy_tank = Tank.new()
	enemy_tank.tank_type = Tank.TankType.BASIC
	enemy_tank.position = base.position
	add_child_autofree(enemy_tank)
	
	# When: Enemy tank collides with base
	base._on_body_entered(enemy_tank)
	
	# Then: Base takes damage
	assert_eq(base.health, 0, "Base should take damage from enemy collision")

func test_given_player_tank_hits_base_when_collision_detected_then_no_damage():
	# Given: Base with full health
	var player_tank = Tank.new()
	player_tank.tank_type = Tank.TankType.PLAYER
	player_tank.position = base.position
	add_child_autofree(player_tank)
	
	# When: Player tank collides with base
	base._on_body_entered(player_tank)
	
	# Then: Base takes no damage
	assert_eq(base.health, 1, "Base should not take damage from player")

## ============================================================================
## Epic: Base Protection (Walls)
## ============================================================================

func test_given_base_created_when_initialized_then_has_surrounding_walls():
	# Given: Base entity
	# When: Checking wall reference
	# Then: Has wall reference for protection
	# Note: Wall management handled by TerrainManager in integration
	pending("Walls tested in integration tests")

func test_given_shovel_active_when_base_protected_then_walls_are_steel():
	# Given: Base with shovel power-up active
	# When: Walls upgraded to steel
	# Then: Walls block all bullets
	# Note: Shovel power-up tested separately
	pending("Power-up system tested separately")

## ============================================================================
## Epic: Base Visual Feedback
## ============================================================================

func test_given_base_destroyed_when_explosion_triggered_then_plays_animation():
	# Given: Base with animation player
	var animation_player = base.get_node_or_null("AnimationPlayer")
	
	# When: Base destroyed
	if animation_player:
		base.health = 1
		base.take_damage(1)
		
		# Then: Explosion animation plays
		# Note: Visual feedback tested in integration
		pending("Visual feedback tested in integration")

func test_given_base_damaged_when_visual_feedback_shown_then_sprite_changes():
	# Given: Base with damage states
	# When: Takes damage but not destroyed
	# Then: Sprite shows damage
	# Note: Visual states tested in integration
	pending("Visual states tested in integration")
