# TANKS1990 - BDD Test Strategy for DDD Architecture

## Overview

This document defines the test strategy for the new Domain-Driven Design architecture, following Behavior-Driven Development (BDD) principles with a test-first (Red-Green-Refactor) approach.

## Testing Philosophy

### BDD Principles

- **Tests describe behavior**, not implementation
- **Given-When-Then** structure for clarity
- **Black-box testing** preferred (test inputs/outputs, not internals)
- **Test-first**: Write failing test → Implement → Refactor

### Test Pyramid

```
        ┌─────────────┐
        │     E2E     │  10% - Complete game scenarios
        │   (Manual)  │
        └─────────────┘
       ┌───────────────┐
       │  Integration  │  20% - Multi-component interactions
       │   (GUT+Mock)  │
       └───────────────┘
      ┌─────────────────┐
      │   Unit Tests    │  70% - Pure domain logic
      │  (GUT, No Mock) │
      └─────────────────┘
```

## Test Categories

### 1. Pure Domain Tests (70% - No Godot Engine)

**Location**: `tests/domain/`

**Characteristics**:

- Run without Godot engine (pure GDScript)
- No mocks needed (pure functions)
- Fast execution (<1ms per test)
- Deterministic

**Test Structure**:

```gdscript
extends GutTest

func test_given_tank_when_takes_damage_then_health_decreases():
    # Given: A tank with 3 health
    var tank = TankEntity.create("t1", TankEntity.Type.PLAYER,
                                 Position.create(5, 5), Direction.up())
    assert_eq(tank.health.current, 3)

    # When: Tank takes 1 damage
    tank.take_damage(1)

    # Then: Health is now 2
    assert_eq(tank.health.current, 2)
    assert_true(tank.is_alive())
```

**Coverage**:

#### Value Objects

- [ ] `test_position.gd` - Position creation, equality, operations
- [ ] `test_direction.gd` - Direction enums, conversions, opposites
- [ ] `test_health.gd` - Health constraints, damage, healing
- [ ] `test_velocity.gd` - Velocity from direction, magnitude
- [ ] `test_tank_stats.gd` - Stats validation, factory methods

#### Entities

- [ ] `test_tank_entity.gd` - Tank behavior (move, shoot, damage, cooldown)
- [ ] `test_bullet_entity.gd` - Bullet movement, activation, deactivation
- [ ] `test_base_entity.gd` - Base destruction, health
- [ ] `test_terrain_cell.gd` - Passability, destruction, types

#### Aggregates

- [ ] `test_stage_state.gd` - Stage bounds, terrain, spawns, completion
- [ ] `test_game_state.gd` - Entity management, invariants, frame advancing

#### Services

- [ ] `test_collision_service.gd` - All collision detection logic
- [ ] `test_movement_service.gd` - Movement validation, execution
- [ ] `test_spawning_service.gd` - Entity creation, cleanup
- [ ] `test_scoring_service.gd` - Score calculation rules

### 2. Command & Event Tests (15% - Pure Logic)

**Location**: `tests/domain/commands/` and `tests/domain/events/`

**Coverage**:

- [ ] `test_commands.gd` - Command creation, validation, serialization
- [ ] `test_events.gd` - Event creation, immutability, serialization
- [ ] `test_command_handler.gd` - Command execution, event emission

**Example**:

```gdscript
func test_given_move_command_when_executed_then_emits_tank_moved_event():
    # Given: Game state with a tank
    var game_state = GameState.create(StageState.create(1, 26, 26))
    var tank = SpawningService.spawn_player_tank(game_state, 0)
    var initial_pos = tank.position

    # When: Move command executed
    var command = MoveCommand.create(tank.id, Direction.right())
    var events = CommandHandler.execute_command(game_state, command)

    # Then: Tank moved and event emitted
    assert_eq(tank.position.x, initial_pos.x + 1)
    assert_eq(events.size(), 1)
    assert_true(events[0] is TankMovedEvent)
    assert_eq(events[0].tank_id, tank.id)
```

### 3. Game Loop Tests (10% - Determinism)

**Location**: `tests/domain/`

**Coverage**:

- [ ] `test_game_loop.gd` - Frame-based updates, determinism
- [ ] `test_replay_system.gd` - Record/replay, deterministic behavior

**Example**:

```gdscript
func test_given_same_seed_when_same_commands_then_identical_results():
    # Given: Two identical game states with same seed
    var state1 = create_test_game_state(seed=12345)
    var state2 = create_test_game_state(seed=12345)

    # When: Execute same sequence of commands
    var commands = [
        MoveCommand.create("player_1", Direction.right()),
        FireCommand.create("player_1"),
        MoveCommand.create("player_1", Direction.up())
    ]

    for command in commands:
        GameLoop.process_frame(state1, [command])
        GameLoop.process_frame(state2, [command])

    # Then: States are identical
    assert_eq(state1.to_dict(), state2.to_dict())
```

### 4. Integration Tests (15% - Adapter Layer)

**Location**: `tests/integration/`

**Characteristics**:

- Test domain ↔ presentation sync
- Requires Godot engine
- Uses GUT framework
- Mocked or stubbed Godot nodes

**Coverage**:

- [ ] `test_godot_adapter.gd` - Domain state → Godot nodes sync
- [ ] `test_input_adapter.gd` - Godot Input → Commands conversion
- [ ] `test_event_adapter.gd` - Domain events → Godot signals
- [ ] `test_full_game_flow.gd` - Complete gameplay scenarios

**Example**:

```gdscript
func test_given_tank_moves_in_domain_when_adapter_syncs_then_node_updated():
    # Given: Game state with tank and adapter
    var game_state = GameState.create(StageState.create(1, 26, 26))
    var tank = SpawningService.spawn_player_tank(game_state, 0)
    var adapter = GodotGameAdapter.new()
    add_child_autofree(adapter)
    adapter.game_state = game_state
    adapter.sync_state_to_presentation()

    var initial_x = tank.position.x

    # When: Tank moves in domain
    var command = MoveCommand.create(tank.id, Direction.right())
    CommandHandler.execute_command(game_state, command)
    adapter.sync_state_to_presentation()

    # Then: Godot node position updated
    var node = adapter.tank_nodes[tank.id]
    assert_eq(node.global_position.x, tank.position.x)
    assert_eq(tank.position.x, initial_x + 1)
```

### 5. E2E Tests (Manual, 5%)

**Location**: Manual testing + `tests/e2e/` (scripts)

**Coverage**:

- Complete gameplay sessions
- Visual verification
- Performance under load
- Edge case scenarios (20 enemies, rapid firing, etc.)

**Checklist**:

- [ ] Player can move in all 4 directions
- [ ] Player can shoot bullets
- [ ] Bullets destroy enemies
- [ ] Enemies move and shoot
- [ ] Collisions work correctly
- [ ] Base destruction ends game
- [ ] Stage completion advances to next stage
- [ ] Score increases on kills
- [ ] Game over on player death (no lives)

## Test Naming Convention

```
test_given_[INITIAL_STATE]_when_[ACTION]_then_[EXPECTED_OUTCOME]
```

**Examples**:

- `test_given_tank_at_bounds_when_moves_out_then_stays_at_bounds`
- `test_given_tank_on_cooldown_when_fires_then_no_bullet_created`
- `test_given_bullet_hits_tank_when_collision_detected_then_tank_takes_damage`

## Red-Green-Refactor Workflow

### Red: Write Failing Test

```gdscript
# tests/domain/test_tank_entity.gd
func test_given_tank_when_rotates_then_direction_changes():
    var tank = TankEntity.create("t1", TankEntity.Type.PLAYER,
                                 Position.create(5, 5), Direction.up())

    tank.rotate_to(Direction.right())

    assert_true(tank.direction.equals(Direction.right()))
```

**Run test**: `make test-unit` → ❌ FAIL (method not implemented)

### Green: Implement Minimal Code

```gdscript
# src/domain/entities/tank_entity.gd
func rotate_to(new_direction: Direction) -> void:
    direction = new_direction
```

**Run test**: `make test-unit` → ✅ PASS

### Refactor: Improve Code Quality

```gdscript
# Refactor if needed (e.g., add validation)
func rotate_to(new_direction: Direction) -> void:
    assert(new_direction != null, "Direction cannot be null")
    direction = new_direction
```

**Run test**: `make test-unit` → ✅ PASS (still works)

## Test Execution Commands

```bash
# Run all domain tests (fast, no Godot engine)
make test-unit

# Run integration tests (requires Godot)
make test-integration

# Run specific test file
make test-file FILE=res://tests/domain/test_tank_entity.gd

# Run with coverage
make test-coverage

# Continuous testing (watch mode)
make test-watch
```

## Coverage Goals

| Component     | Target Coverage |
| ------------- | --------------- |
| Value Objects | 100%            |
| Entities      | 95%             |
| Aggregates    | 90%             |
| Services      | 90%             |
| Commands      | 100%            |
| Events        | 100%            |
| Adapters      | 80%             |
| Overall       | 90%+            |

## Mocking Strategy

### AVOID Mocking in Domain Tests

Domain tests should use real objects (pure logic, no side effects).

```gdscript
# ❌ BAD: Don't mock domain objects
var mock_tank = MockTank.new()
mock_tank.should_receive("take_damage").with(1)

# ✅ GOOD: Use real domain objects
var tank = TankEntity.create("t1", TankEntity.Type.PLAYER,
                            Position.create(5, 5), Direction.up())
tank.take_damage(1)
assert_eq(tank.health.current, 2)
```

### Mock ONLY External Dependencies

Use mocks for Godot engine or I/O operations in integration tests.

```gdscript
# ✅ Acceptable: Mock Godot Node in integration test
var mock_node = MockNode3D.new()
mock_node.global_position = Vector3.ZERO
```

## Determinism Requirements

### All Tests Must Be Deterministic

- Use explicit seeds for RNG
- Use frame numbers, not time
- No random test data
- Fixed test inputs

```gdscript
# ✅ Deterministic test
func test_tank_spawning_with_seed():
    var rng = RandomProvider.create_with_seed(12345)
    var game_state = create_game_state_with_rng(rng)

    var tank1 = spawn_random_enemy(game_state)
    var tank2 = spawn_random_enemy(game_state)

    # Results are always the same with same seed
    assert_eq(tank1.tank_type, TankEntity.Type.ENEMY_FAST)
    assert_eq(tank2.tank_type, TankEntity.Type.ENEMY_BASIC)
```

## Test Data Builders (Factories)

Create helper functions for common test scenarios:

```gdscript
# tests/helpers/test_builders.gd
class_name TestBuilders

static func create_player_tank(id: String = "player_1",
                                x: int = 5, y: int = 5) -> TankEntity:
    return TankEntity.create(id, TankEntity.Type.PLAYER,
                             Position.create(x, y), Direction.up())

static func create_game_state_with_one_tank() -> GameState:
    var stage = StageState.create(1, 26, 26)
    stage.add_player_spawn(Position.create(5, 20))

    var game_state = GameState.create(stage)
    SpawningService.spawn_player_tank(game_state, 0)

    return game_state
```

## Migration Test Strategy

### Phase 1: Domain Tests First

1. Write tests for value objects
2. Implement value objects until tests pass
3. Write tests for entities
4. Implement entities until tests pass
5. Continue for aggregates, services

### Phase 2: Keep Old Tests Passing

- Do NOT delete existing tests immediately
- Run both old and new tests during migration
- Gradually replace old tests with new BDD tests

### Phase 3: Test-Driven Migration

For each old component:

1. Write new BDD test for domain equivalent
2. Implement domain component
3. Update adapter to bridge old/new
4. Verify both work
5. Remove old component

## Success Criteria

✅ **All domain tests pass without Godot engine**
✅ **90%+ code coverage on domain layer**
✅ **All tests are deterministic (same input → same output)**
✅ **Tests follow Given-When-Then structure**
✅ **Test execution time <5 seconds for unit tests**
✅ **All failing tests from current codebase resolved**
✅ **Integration tests verify domain ↔ presentation sync**
✅ **Manual E2E checklist 100% passed**

## References

- BDD: _"Behavior-Driven Development with Behat"_ - Everzet
- TDD: _"Test-Driven Development: By Example"_ - Kent Beck
- Testing Patterns: _"xUnit Test Patterns"_ - Gerard Meszaros
