# TANKS1990 - DDD Architecture Design

**Goal**: Decouple game logic from Godot engine for deterministic, portable, server-capable game flow.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  (Godot Nodes: Tank3D, Bullet3D, Camera, Rendering)    │
└─────────────────┬───────────────────────────────────────┘
                  │
          ┌───────▼────────┐
          │  Adapter Layer  │
          │  (Sync State)   │
          └───────┬────────┘
                  │
┌─────────────────▼───────────────────────────────────────┐
│                    Domain Layer                          │
│  Pure GDScript (RefCounted): No Godot Dependencies      │
│                                                          │
│  ┌────────────┐  ┌──────────────┐  ┌─────────────────┐ │
│  │ Commands   │  │ Game State   │  │ Domain Events   │ │
│  │ (Input)    │──▶│ (Aggregate)  │──▶│ (Output)        │ │
│  └────────────┘  └──────────────┘  └─────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │ Domain Services:                                   │ │
│  │ - CollisionService                                 │ │
│  │ - MovementService                                  │ │
│  │ - SpawningService                                  │ │
│  │ - ScoringService                                   │ │
│  └────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

## Core Principles

1. **Pure Domain Logic**: All game logic in `src/domain/` - no `extends Node`
2. **Frame-Based**: Use frame numbers, not time (deterministic)
3. **Integer Coordinates**: Tile-based (26x26 grid), not pixels
4. **Immutable Commands**: Inputs are value objects
5. **Immutable Events**: Outputs are records of state changes
6. **Command → State → Events**: One-way data flow
7. **Testable**: All domain code runs without Godot engine

## Folder Structure

```
src/
├── domain/                    # Pure game logic (NO Godot dependencies)
│   ├── entities/              # Mutable with identity
│   │   ├── tank_entity.gd
│   │   ├── bullet_entity.gd
│   │   ├── base_entity.gd
│   │   └── terrain_cell.gd
│   ├── value_objects/         # Immutable data
│   │   ├── position.gd
│   │   ├── direction.gd
│   │   ├── health.gd
│   │   ├── velocity.gd
│   │   └── tank_stats.gd
│   ├── aggregates/            # Consistency boundaries
│   │   ├── game_state.gd      # Root aggregate
│   │   └── stage_state.gd
│   ├── commands/              # Input commands
│   │   ├── command.gd         # Base class
│   │   ├── move_command.gd
│   │   ├── fire_command.gd
│   │   └── rotate_command.gd
│   ├── events/                # Domain events
│   │   ├── domain_event.gd    # Base class
│   │   ├── tank_events.gd
│   │   ├── bullet_events.gd
│   │   └── game_events.gd
│   ├── services/              # Domain logic
│   │   ├── collision_service.gd
│   │   ├── movement_service.gd
│   │   ├── spawning_service.gd
│   │   ├── scoring_service.gd
│   │   └── command_handler.gd
│   └── repositories/          # State persistence
│       ├── game_state_repository.gd
│       └── stage_repository.gd
│
├── adapters/                  # Bridge domain ↔ presentation
│   ├── godot_game_adapter.gd  # Syncs domain state to Godot nodes
│   ├── input_adapter.gd       # Converts Godot input → Commands
│   └── event_adapter.gd       # Converts domain events → Godot signals
│
└── presentation/              # Godot-specific (Nodes, Scenes)
    ├── entities/              # Visual representation
    │   ├── tank3d.gd          # Extends Node3D
    │   └── bullet3d.gd
    └── managers/
        └── presentation_manager.gd
```

## Domain Model Components

### Value Objects (Immutable)

**Purpose**: Primitives with business meaning and validation.

- `Position(x: int, y: int)` - Tile coordinates
- `Direction(UP/DOWN/LEFT/RIGHT)` - Cardinal directions
- `Health(current: int, maximum: int)` - HP with max constraint
- `Velocity(dx: int, dy: int)` - Movement speed per frame
- `TankStats(speed, fire_rate, armor, bullet_speed)` - Tank capabilities

**Key Properties**:

- Immutable (no setters)
- Equality by value
- Factory methods for construction
- Validation in constructor

### Entities (Mutable with Identity)

**Purpose**: Objects with lifecycle and identity.

- `TankEntity` - Tank state (position, health, cooldown, etc.)
- `BulletEntity` - Bullet state (position, velocity, owner)
- `BaseEntity` - Eagle building
- `TerrainCell` - Single grid tile (brick, steel, water, etc.)

**Key Properties**:

- Has unique `id: String`
- Mutable state
- Methods for behavior (move, take_damage, etc.)
- Enforces invariants

### Aggregates (Consistency Boundaries)

**Purpose**: Groups of entities with consistency rules.

**`StageState`** - Single stage/level

- Terrain grid (26x26)
- Base entity
- Spawn positions
- Enemy quota (20 total, 4 max on field)

**`GameState`** (Root Aggregate)

- Current frame number
- StageState
- All tanks (Dictionary: id → TankEntity)
- All bullets (Dictionary: id → BulletEntity)
- Player lives
- Score
- Pause/game over flags

**Invariants**:

- All tanks within bounds
- All bullets active or removed
- Player lives ≥ 0
- Score ≥ 0

### Domain Services

**Purpose**: Logic that doesn't belong to a single entity.

- `CollisionService` - Detect collisions (pure functions)
- `MovementService` - Validate and execute movement
- `SpawningService` - Create tanks, bullets, power-ups
- `ScoringService` - Calculate score from kills
- `CommandHandler` - Execute commands on GameState

**Grid-Based Collision System**:

All collision detection uses exact grid position matching via `Position.equals()`. This ensures:

- **Zero Godot coupling** - No pixel calculations, physics engines, or node queries
- **Deterministic behavior** - Integer comparisons are exact, no floating-point errors
- **Network-ready** - Pure domain logic that can run on server or client

```gdscript
# Tank-bullet collision (src/domain/services/collision_service.gd:20-33)
static func check_tank_bullet_collision(tank: TankEntity, bullet: BulletEntity) -> bool:
    if not tank.is_alive() or not bullet.is_active:
        return false
    if tank.id == bullet.owner_id:  # Can't hit own bullet
        return false
    return tank.position.equals(bullet.position)  # Exact grid match

# Bullet-bullet collision (lines 123-138)
static func check_bullet_to_bullet_collision(b1: BulletEntity, b2: BulletEntity) -> bool:
    if not b1.is_active or not b2.is_active:
        return false
    if b1.owner_id == b2.owner_id:  # Same owner's bullets don't collide
        return false
    return b1.position.equals(b2.position)  # Exact grid match

# Bullet-terrain collision (lines 48-56)
static func check_bullet_terrain_collision(bullet: BulletEntity, terrain_cell: TerrainCell) -> bool:
    if not bullet.position.equals(terrain_cell.position):
        return false
    return not terrain_cell.is_passable_for_bullet()
```

**Position.equals() Implementation**:

```gdscript
# src/domain/value_objects/position.gd
func equals(other: Position) -> bool:
    return x == other.x and y == other.y  # Integer comparison
```

Bullets collide when at the exact same grid tile, regardless of:

- Movement direction
- Pixel offsets (handled by presentation layer)
- Animation states
- Visual interpolation

This matches the NES original's tile-based collision model

### Commands (Inputs)

**Purpose**: Represent player/AI intent.

```gdscript
class_name MoveCommand extends Command
var tank_id: String
var direction: Direction
```

- `MoveCommand`
- `FireCommand`
- `RotateCommand`
- `PauseCommand`

**Properties**:

- Immutable
- Validated before execution
- Serializable (for replays)

### Domain Events (Outputs)

**Purpose**: Record of state changes.

```gdscript
class_name TankMovedEvent extends DomainEvent
var frame: int
var tank_id: String
var from_position: Position
var to_position: Position
var direction: Direction
```

Events for all state changes:

- `TankSpawnedEvent`
- `TankMovedEvent`
- `TankDamagedEvent`
- `TankDestroyedEvent`
- `BulletFiredEvent`
- `BulletDestroyedEvent`
- `CollisionEvent`
- `ScoreChangedEvent`

**Properties**:

- Immutable
- Frame number (when it happened)
- All relevant data
- Serializable

## Game Loop (Deterministic)

```gdscript
func process_frame(game_state: GameState, commands: Array[Command]) -> Array[DomainEvent]:
    var events: Array[DomainEvent] = []

    # 1. Execute commands (player/AI inputs)
    for command in commands:
        events.append_array(CommandHandler.execute_command(game_state, command))

    # 2. Update cooldowns
    for tank in game_state.get_all_tanks():
        tank.update_cooldown()

    # 3. Move bullets
    MovementService.update_all_bullets(game_state)

    # 4. Detect collisions
    var collision_events = CollisionService.detect_all_collisions(game_state)
    events.append_array(collision_events)

    # 5. Apply collision consequences
    for event in collision_events:
        if event is BulletHitTankEvent:
            var tank = game_state.get_tank(event.tank_id)
            tank.take_damage(event.damage)
            if not tank.is_alive():
                events.append(TankDestroyedEvent.create(game_state.frame, tank.id))

    # 6. Remove destroyed entities
    SpawningService.remove_destroyed_entities(game_state)

    # 7. Check win/loss conditions
    if game_state.is_stage_complete():
        events.append(StageCompleteEvent.create(game_state.frame))
    elif game_state.is_stage_failed():
        events.append(GameOverEvent.create(game_state.frame, "Base destroyed"))

    # 8. Advance frame
    game_state.advance_frame()

    return events
```

## Adapter Layer

**Purpose**: Sync pure domain state to Godot presentation.

```gdscript
class_name GodotGameAdapter extends Node

var game_state: GameState
var tank_nodes: Dictionary  # tank_id → Tank3D node
var bullet_nodes: Dictionary  # bullet_id → Bullet3D node

func sync_state_to_presentation() -> void:
    # Sync all tanks
    for tank in game_state.get_all_tanks():
        var node = tank_nodes.get(tank.id)
        if not node:
            node = _create_tank_node(tank)
            tank_nodes[tank.id] = node
        _update_tank_node(node, tank)

    # Sync all bullets
    for bullet in game_state.get_all_bullets():
        var node = bullet_nodes.get(bullet.id)
        if not node:
            node = _create_bullet_node(bullet)
            bullet_nodes[bullet.id] = node
        _update_bullet_node(node, bullet)

    # Remove dead entities
    _cleanup_destroyed_nodes()

func _update_tank_node(node: Tank3D, entity: TankEntity) -> void:
    # Convert tile coords to 3D position
    node.global_position = Vector3(entity.position.x, 0, entity.position.y)
    node.visible = entity.is_alive()
    # Update rotation based on direction
    # etc.
```

## Domain Purity Verification

**Automated Verification**: The domain layer is continuously verified for zero Godot coupling:

```bash
make verify-domain
```

This script (`scripts/verify_domain_purity.sh`) checks all files in `src/domain/` for:

- ❌ Node inheritance (`extends Node`, `extends Node2D`, `extends Node3D`)
- ❌ Godot annotations (`@export`, `@onready`)
- ❌ Scene tree access (`get_node()`, `$NodePath`, `get_tree()`)
- ❌ Scene/resource loading (`load("res://...tscn")`)
- ❌ Engine singletons (`Engine.`, `OS.`)
- ✅ Only `extends RefCounted` or `extends Object` allowed

**Example Output**:

```
=== Domain Layer Purity Verification ===
Scanning domain files...
✅ src/domain/entities/tank_entity.gd
✅ src/domain/entities/bullet_entity.gd
✅ src/domain/services/collision_service.gd
...

✅ VERIFICATION PASSED
39 files scanned, 0 violations found
```

**CI Integration**: This check runs in continuous integration to prevent accidental coupling:

```bash
make validate  # Runs tests + verify-domain
```

**Why This Matters**:

- Guarantees domain logic can run without Godot engine
- Enables server-side game state computation
- Facilitates porting to other engines or platforms
- Supports deterministic replays and networked multiplayer
- Makes unit tests fast (no engine initialization)

## Testing Strategy

### Pure Domain Tests (No Godot)

```gdscript
# tests/domain/test_tank_entity.gd
extends GutTest

func test_tank_can_take_damage():
    # Given
    var tank = TankEntity.create("t1", TankEntity.Type.PLAYER,
                                 Position.create(5, 5), Direction.up())

    # When
    tank.take_damage(1)

    # Then
    assert_eq(tank.health.current, 2)
    assert_true(tank.is_alive())

func test_tank_dies_when_health_reaches_zero():
    var tank = TankEntity.create("t1", TankEntity.Type.PLAYER,
                                 Position.create(5, 5), Direction.up())

    tank.take_damage(3)

    assert_false(tank.is_alive())
```

### Integration Tests (With Adapter)

```gdscript
# tests/integration/test_movement_integration.gd
extends GutTest

func test_tank_movement_updates_godot_node():
    var game_state = GameState.create(StageState.create(1, 26, 26))
    var adapter = GodotGameAdapter.new()

    var tank = SpawningService.spawn_player_tank(game_state, 0)
    adapter.sync_state_to_presentation()

    var command = MoveCommand.create(tank.id, Direction.right())
    CommandHandler.execute_command(game_state, command)

    adapter.sync_state_to_presentation()

    var node = adapter.tank_nodes[tank.id]
    assert_eq(node.global_position.x, tank.position.x)
```

## Migration Plan

### Phase 1: Domain Model (Week 1-2)

- [ ] Create `src/domain/` folder structure
- [ ] Implement all value objects
- [ ] Implement all entities
- [ ] Implement aggregates (GameState, StageState)
- [ ] Write unit tests for each class
- [ ] All tests pass without Godot engine

### Phase 2: Domain Services (Week 2-3)

- [ ] Implement CollisionService
- [ ] Implement MovementService
- [ ] Implement SpawningService
- [ ] Implement ScoringService
- [ ] Write service tests
- [ ] Integration tests for service interactions

### Phase 3: Commands & Events (Week 3-4)

- [ ] Define all command classes
- [ ] Define all event classes
- [ ] Implement CommandHandler
- [ ] Write command execution tests
- [ ] Test event emission

### Phase 4: Game Loop (Week 4-5)

- [ ] Implement pure game loop
- [ ] Frame-based update
- [ ] Test deterministic behavior
- [ ] Record/replay system

### Phase 5: Adapter Layer (Week 5-6)

- [ ] Implement GodotGameAdapter
- [ ] Sync domain state → Godot nodes
- [ ] InputAdapter: Godot input → Commands
- [ ] EventAdapter: Domain events → Godot signals
- [ ] Integration tests

### Phase 6: Presentation Update (Week 6-7)

- [ ] Refactor Tank3D to be pure view
- [ ] Refactor Bullet3D to be pure view
- [ ] Update existing scenes
- [ ] Maintain visual compatibility

### Phase 7: Migration & Cleanup (Week 7-8)

- [ ] Migrate all tests
- [ ] Remove old coupled code
- [ ] Update documentation
- [ ] Performance testing
- [ ] Final integration

## Benefits

✅ **Deterministic**: Same inputs always produce same outputs
✅ **Testable**: No mocks needed, pure functions
✅ **Portable**: Can run on server, in headless mode, or different engines
✅ **Replayable**: Commands + seed = exact replay
✅ **Maintainable**: Clear separation of concerns
✅ **Fast**: No scene tree queries, direct object access
✅ **Server-Ready**: Can compute game state server-side

## References

- Domain-Driven Design (Eric Evans)
- Clean Architecture (Robert C. Martin)
- Implementing Domain-Driven Design (Vaughn Vernon)
- Game Programming Patterns (Robert Nystrom)
