# DDD Adapter Layer Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                           │
│              (Godot Nodes: Tank3D, Bullet3D, UI)                 │
│                                                                   │
│  - Visual rendering                                              │
│  - Camera systems                                                │
│  - Effects (particles, trails)                                   │
│  - Audio playback                                                │
└──────────────┬──────────────────────────────────────────────────┘
               │ signals (tank_spawned, bullet_fired, etc.)
               │
┌──────────────▼──────────────────────────────────────────────────┐
│                      ADAPTER LAYER                               │
│              (Bridges Domain ↔ Presentation)                     │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  GodotGameAdapter (extends Node)                         │   │
│  │                                                           │   │
│  │  • Manages GameState                                     │   │
│  │  • _physics_process(60 FPS)                              │   │
│  │  • Converts domain events → Godot signals                │   │
│  │  • Tracks entity lifecycle (spawn/destroy)               │   │
│  │  • Coordinate conversion (tile ↔ pixel)                  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  InputAdapter (extends RefCounted)                        │   │
│  │                                                           │   │
│  │  • Converts Godot Input → Commands                       │   │
│  │  • Arrow keys → MoveCommand                              │   │
│  │  • Fire key → FireCommand                                │   │
│  └─────────────────────────────────────────────────────────┘   │
└──────────────┬──────────────────────────────────────────────────┘
               │ Commands (immutable)
               │
┌──────────────▼──────────────────────────────────────────────────┐
│                      DOMAIN LAYER                                │
│            (Pure GDScript, extends RefCounted)                   │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  GameLoop (static)                                        │   │
│  │                                                           │   │
│  │  process_frame(game_state, commands) → events            │   │
│  │    1. Execute commands                                   │   │
│  │    2. Update cooldowns                                   │   │
│  │    3. Move bullets                                       │   │
│  │    4. Detect collisions                                  │   │
│  │    5. Remove destroyed entities                          │   │
│  │    6. Check win/loss                                     │   │
│  │    7. Advance frame                                      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  GameState (Aggregate Root)                               │   │
│  │                                                           │   │
│  │  • frame: int                                            │   │
│  │  • stage: StageState                                     │   │
│  │  • tanks: Dictionary                                     │   │
│  │  • bullets: Dictionary                                   │   │
│  │  • score: int                                            │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌───────────────┬───────────────┬──────────────────────────┐  │
│  │ Entities      │ Value Objects │ Services                  │  │
│  │               │               │                           │  │
│  │ • TankEntity  │ • Position    │ • CommandHandler          │  │
│  │ • BulletEntity│ • Direction   │ • MovementService         │  │
│  │ • BaseEntity  │ • Health      │ • CollisionService        │  │
│  │               │ • TankStats   │ • SpawningService         │  │
│  └───────────────┴───────────────┴──────────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘
```

## Data Flow

### Input to Domain (per frame)

```
Player Input
    ↓
Input.is_action_pressed("move_up")
    ↓
InputAdapter.get_commands_for_frame()
    ↓
[MoveCommand(tank_id, Direction.UP, frame)]
    ↓
GameLoop.process_frame(game_state, commands)
    ↓
CommandHandler.execute_command()
    ↓
TankEntity.move(direction)
    ↓
[TankMovedEvent(tank_id, old_pos, new_pos, frame)]
```

### Domain to Presentation (per frame)

```
GameLoop.process_frame()
    ↓
Array[DomainEvent]
    ↓
GodotGameAdapter._process_domain_events()
    ↓
adapter.sync_state_to_presentation()
    ↓
Compare domain state with tracked state
    ↓
Emit Godot signals for changes:
  • tank_spawned
  • tank_moved
  • bullet_fired
    ↓
Presentation Layer updates visuals
```

## Frame Processing (60 FPS)

```
┌─────────────────────────────────────────────────────────────┐
│  GodotGameAdapter._physics_process(delta)                    │
│                                                              │
│  Frame N:                                                    │
│                                                              │
│  1. Get input commands                                      │
│     └─ InputAdapter.get_commands_for_frame()               │
│                                                              │
│  2. Process domain frame                                    │
│     └─ GameLoop.process_frame(game_state, commands)        │
│        └─ Returns Array[DomainEvent]                       │
│                                                              │
│  3. Convert domain events to signals                        │
│     └─ _process_domain_events(events)                      │
│        └─ Emit game_over, stage_complete                   │
│                                                              │
│  4. Sync state to presentation                              │
│     └─ sync_state_to_presentation()                        │
│        ├─ _sync_tanks()                                    │
│        │  └─ Emit tank_spawned, tank_moved, tank_damaged  │
│        ├─ _sync_bullets()                                  │
│        │  └─ Emit bullet_fired, bullet_moved              │
│        └─ _cleanup_removed_entities()                      │
│           └─ Emit tank_destroyed, bullet_destroyed        │
│                                                              │
│  5. Frame advances (game_state.frame++)                     │
└─────────────────────────────────────────────────────────────┘
```

## Coordinate Systems

### Domain (Tile-based)

- Grid: 26x26 tiles
- Position: Position(x: int, y: int)
- Example: Position(13, 12) = center of map

### Presentation (Pixel-based)

- Screen: 832x832 pixels (or 3D units)
- Position: Vector2(x: float, y: float)
- Conversion: pixel = tile \* TILE_SIZE (16 pixels)
- Example: Position(13, 12) → Vector2(208, 192)

## Signal Flow

```
Domain Event               Adapter Signal                  Presentation
─────────────             ─────────────────              ──────────────
TankSpawnedEvent    →     tank_spawned(id, pos, type)  → Create Tank3D node
TankMovedEvent      →     tank_moved(id, old, new)     → Update position
TankDamagedEvent    →     tank_damaged(id, dmg, hp)    → Show damage effect
TankDestroyedEvent  →     tank_destroyed(id, pos)      → Explosion effect
BulletFiredEvent    →     bullet_fired(id, pos, dir)   → Create Bullet3D
BulletMovedEvent    →     bullet_moved(id, old, new)   → Update position
BulletDestroyedEvent→     bullet_destroyed(id, pos)    → Remove node
StageCompleteEvent  →     stage_complete()             → Show victory UI
GameOverEvent       →     game_over(reason)            → Show game over UI
```

## Testing Strategy

### Unit Tests (Domain)

- 366 tests for pure domain logic
- No Godot dependencies
- Fast execution (< 1 second)
- 100% deterministic

### Integration Tests (Adapter)

- 9 tests for adapter layer
- Tests domain ↔ presentation bridge
- Verifies signal emission
- Validates state synchronization

### Total Coverage

- 375 tests (100% passing)
- Comprehensive domain + integration coverage
- BDD-style assertions

## Key Design Decisions

1. **RefCounted Domain**: Pure logic, no Node overhead
2. **Frame-Based**: Deterministic, replayable, networkable
3. **Event-Driven**: Loose coupling via signals
4. **Immutable Commands/Events**: Safe concurrent access
5. **Aggregate Pattern**: GameState as consistency boundary
6. **Adapter Pattern**: Clean separation of concerns
7. **Test-First**: BDD approach ensures correctness

## Performance Characteristics

- **Domain Update**: < 1ms per frame (60 FPS)
- **State Sync**: O(n) where n = active entities
- **Memory**: Minimal overhead (tracking dictionaries only)
- **GC Pressure**: Low (RefCounted auto-cleanup)

## Future Enhancements

1. **Interpolation**: Smooth movement between frames
2. **Prediction**: Client-side prediction for network play
3. **Rollback**: Time-travel debugging
4. **Recording**: Replay system via events
5. **Network**: Sync commands across clients
