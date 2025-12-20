# TANKS1990 - Testing Guide

Complete guide to running and writing tests for the TANKS1990 project.

## Quick Start

```bash
# Run all tests (with pre-checks)
make test

# Run specific test suite
make test SUITE=domain
make test SUITE=integration
make test SUITE=unit

# Run tests matching a pattern
make test PATTERN=test_tank
make test SUITE=domain PATTERN=test_tank_entity
```

## Test Structure

The project follows a comprehensive testing strategy aligned with DDD architecture:

```
tests/
├── domain/               # 268 tests - Pure domain logic
│   ├── entities/        # Entity behavior tests
│   ├── services/        # Domain service tests
│   ├── value_objects/   # Value object tests
│   └── aggregates/      # Game state tests
│
├── integration/         # 29 tests - Component interactions
│   ├── test_3d_shooting_mechanics.gd
│   ├── test_game_loop_integration.gd
│   └── test_adapter_sync.gd
│
├── unit/                # Unit tests (legacy 2D code)
│   └── [2D scene tests]
│
└── hooks/               # Test utilities
    ├── pre_run_hook.gd  # Test setup
    └── compile_check.gd # Compilation validation
```

## Test Categories

### Domain Tests (268 tests)

**Purpose**: Test pure game logic without Godot engine dependencies

**Characteristics**:

- No `extends Node` - all pure `RefCounted` classes
- Deterministic and fast (<1ms per test)
- Frame-based, not time-based
- Integer coordinates (tile-based)

**Examples**:

```bash
# All domain tests
make test SUITE=domain

# Tank entity tests
make test SUITE=domain PATTERN=test_tank_entity

# Collision service tests
make test SUITE=domain PATTERN=test_collision_service
```

**Test Structure** (BDD Style):

```gdscript
extends GutTest

func test_given_tank_at_position_when_moving_north_then_position_updates():
    # Arrange - Given
    var tank = TankEntity.new()
    tank.set_position(Position.new(10, 10))

    # Act - When
    var command = MoveCommand.new(tank.id, Direction.NORTH)
    game_state.execute_command(command)

    # Assert - Then
    assert_eq(tank.get_position().y, 9, "Tank moved north")
```

### Integration Tests (29 tests)

**Purpose**: Test interactions between domain layer, adapter layer, and presentation

**Characteristics**:

- Test multiple components working together
- Include Godot node interactions
- Test adapter layer synchronization
- Validate domain events → Godot signals

**Examples**:

```bash
# All integration tests
make test SUITE=integration

# Shooting mechanics integration
make test SUITE=integration PATTERN=test_3d_shooting_mechanics
```

### Unit Tests (Legacy)

**Purpose**: Tests for legacy 2D scenes (being phased out)

**Status**: Maintained for 2D compatibility, will be removed after full 3D migration

## Pre-Check System

The Makefile includes a robust pre-check system that runs before tests:

### 1. Asset Validation (`check-only`)

- Validates all assets are correctly configured
- Checks project integrity
- Fails early if assets are corrupted

### 2. Asset Import (`check-import`)

- Ensures all assets are imported
- Catches import errors before test execution

### 3. Compilation Check (`check-compile`)

- Validates all GDScript files compile
- Catches syntax errors early
- Prevents running tests with broken code

**Why pre-checks matter**: Failing tests due to asset issues or syntax errors waste time. Pre-checks catch these problems before test execution.

## Common Test Commands

### Run All Tests

```bash
make test
```

Runs: `precheck` → domain tests → integration tests → unit tests

**Output**: Summary showing total passed/failed tests

### Run Specific Suite

```bash
# Domain tests only (pure game logic)
make test SUITE=domain

# Integration tests only (adapter + presentation)
make test SUITE=integration

# Unit tests only (legacy 2D)
make test SUITE=unit
```

### Run Tests by Pattern

```bash
# Run all tests with "tank" in the name
make test PATTERN=test_tank

# Run specific entity tests in domain suite
make test SUITE=domain PATTERN=test_tank_entity

# Run collision-related tests
make test PATTERN=collision
```

### Validate Entire Project

```bash
make validate
```

Runs: `precheck` → all tests → verification

Use this before committing code or creating pull requests.

## Writing Tests

### BDD Test Structure

All tests follow **Given-When-Then** pattern:

```gdscript
extends GutTest

func test_given_[context]_when_[action]_then_[outcome]():
    # Arrange - Given (setup initial state)
    var game_state = GameState.new()
    var tank = TankEntity.new()
    game_state.add_tank(tank)

    # Act - When (perform action)
    var command = FireCommand.new(tank.id)
    var events = game_state.execute_command(command)

    # Assert - Then (verify outcome)
    assert_eq(events.size(), 1, "One event emitted")
    assert_true(events[0] is BulletSpawnedEvent, "Bullet spawned")
```

### Test Naming Convention

- **Descriptive**: Test names describe the behavior being tested
- **Pattern**: `test_given_X_when_Y_then_Z`
- **Readable**: Tests serve as documentation

**Examples**:

- `test_given_tank_at_wall_when_moving_forward_then_collision_detected()`
- `test_given_bullet_hits_enemy_when_processing_collisions_then_enemy_destroyed()`
- `test_given_game_paused_when_receiving_input_then_no_state_changes()`

### Domain Test Template

```gdscript
extends GutTest

# Test class for [ComponentName]
# Tests cover: [list main behaviors]

func before_each():
    # Setup common test state
    pass

func after_each():
    # Cleanup
    pass

func test_given_initial_state_when_created_then_valid_defaults():
    # Test initialization
    pass

func test_given_valid_input_when_performing_action_then_state_updated():
    # Test state changes
    pass

func test_given_invalid_input_when_performing_action_then_error_handled():
    # Test error cases
    pass
```

### Integration Test Template

```gdscript
extends GutTest

# Integration test for [feature]
# Tests interaction between: [list components]

var game_adapter: GodotGameAdapter
var scene_root: Node3D

func before_each():
    # Create test scene hierarchy
    scene_root = Node3D.new()
    add_child(scene_root)

    game_adapter = GodotGameAdapter.new()
    scene_root.add_child(game_adapter)

    await get_tree().process_frame

func after_each():
    # Cleanup
    scene_root.queue_free()

func test_given_domain_entity_spawned_when_processing_frame_then_node_created():
    # Arrange
    var tank_id = game_adapter.game_state.spawn_tank(Position.new(10, 10))

    # Act
    game_adapter._physics_process(0.016)
    await get_tree().process_frame

    # Assert
    var tank_node = game_adapter.get_tank_node(tank_id)
    assert_not_null(tank_node, "Tank node created")
    assert_almost_eq(tank_node.position.x, 400.0, 0.1, "Position synced")
```

## Test-Driven Development (TDD)

### Red-Green-Refactor Cycle

1. **Red**: Write failing test first

   ```bash
   make test SUITE=domain PATTERN=test_new_feature
   # Test fails - feature not implemented
   ```

2. **Green**: Implement minimal code to pass test

   ```bash
   # Implement feature in src/domain/
   make test SUITE=domain PATTERN=test_new_feature
   # Test passes
   ```

3. **Refactor**: Improve code while keeping tests green
   ```bash
   # Refactor implementation
   make test  # All tests still pass
   ```

### TDD Best Practices

- Write test before implementation
- Start with simplest test case
- Add edge cases incrementally
- Keep tests fast and focused
- One assertion per test (when possible)
- Use descriptive test names

## Continuous Integration

### Pre-Commit Checklist

```bash
# 1. Run all tests
make test

# 2. Validate entire project
make validate

# 3. Check git status
git status

# 4. Commit with descriptive message
git add .
git commit -m "feat: implement tank collision detection"
```

### CI Pipeline (Recommended)

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Godot
        uses: godotengine/godot-action@v3
        with:
          version: "4.5"

      - name: Run Tests
        run: make test
```

## Troubleshooting

### Test Failures

**Symptom**: Tests fail after code changes

**Solution**:

```bash
# 1. Check pre-checks pass
make precheck

# 2. Run specific failing test
make test SUITE=domain PATTERN=test_failing_test

# 3. Check compilation
make check-compile

# 4. Review test output for assertion details
```

### Asset Errors

**Symptom**: Tests fail with "cannot load resource" errors

**Solution**:

```bash
# Validate and import assets
make check-only
make check-import

# Open editor to reimport
make edit
```

### Compilation Errors

**Symptom**: Tests don't run, syntax errors shown

**Solution**:

```bash
# Check compilation explicitly
make check-compile

# Fix syntax errors in reported files
# Re-run check
make check-compile
```

### Timeout Issues

**Symptom**: Integration tests hang or timeout

**Solution**:

- Check for infinite loops in game logic
- Add timeout guards in tests
- Verify `await get_tree().process_frame` usage
- Check for missing `queue_free()` in cleanup

## Performance Considerations

### Test Speed

- **Domain tests**: <1ms each (target)
- **Integration tests**: <50ms each (target)
- **Total suite**: <30 seconds (target)

### Optimization Tips

- Keep domain tests pure (no Godot engine)
- Minimize `await` calls in tests
- Use `before_all()` for expensive setup
- Clean up resources in `after_each()`
- Avoid unnecessary scene instantiation

## Additional Resources

- [DDD Architecture](DDD_ARCHITECTURE.md) - Domain-Driven Design principles
- [BDD Test Strategy](BDD_TEST_STRATEGY.md) - Detailed testing philosophy
- [Adapter Architecture](ADAPTER_ARCHITECTURE.md) - How layers communicate
- [GUT Documentation](https://github.com/bitwes/Gut) - Testing framework

## Summary

| Command                       | Purpose                       |
| ----------------------------- | ----------------------------- |
| `make test`                   | Run all tests with pre-checks |
| `make test SUITE=domain`      | Run domain tests only         |
| `make test SUITE=integration` | Run integration tests only    |
| `make test PATTERN=test_tank` | Run tests matching pattern    |
| `make validate`               | Full project validation       |
| `make precheck`               | Run pre-checks only           |

**Current Status**: ✅ 297 tests passing (268 domain + 29 integration)
