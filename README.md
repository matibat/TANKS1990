# Tank 1990 - Godot Remake

Classic NES Tank 1990 (Battle City) remake built with Godot 4.5+ using Domain-Driven Design architecture.

## Features

- **Faithful Remake:** Core tank combat mechanics from the NES original
- **DDD Architecture:** Clean separation between game logic and presentation
- **Fully Tested:** 375 tests (366 domain + 9 integration) - 100% passing ✅
- **3D Graphics:** Modern 3D rendering with classic top-down gameplay ✨
- **Combat System:** Friendly fire prevention, spawn invulnerability (3s), bullet collision priority
- **Player Systems:** Lives and respawn mechanics with visual flicker effects
- **Enemy Scoring:** 100-400 points per kill based on enemy type
- **Cross-Platform:** Desktop (Windows, macOS, Linux) and Mobile (iOS, Android)
- **Deterministic:** Frame-based game logic for replays and networking
- **Debug Logging:** Production-safe logging system for development

## Quick Start

```bash
# Clone and setup
git clone https://github.com/matibat/TANKS1990.git
cd TANKS1990
git submodule update --init --recursive

# Run the 3D game 🎮
make demo3d

# Run all tests
make test

# Open in Godot editor
make edit
```

## Setup

### Prerequisites

- Godot 4.5 or later
- Git
- Make (for build automation)

### Installation

1. Clone the repository:

```bash
git clone https://github.com/matibat/TANKS1990.git
cd TANKS1990
```

2. Initialize submodules (GUT testing framework):

```bash
git submodule update --init --recursive
```

3. Verify setup:

```bash
make test
```

All 375 tests should pass ✅

## Architecture

The game follows **Domain-Driven Design (DDD)** principles with clean separation of concerns:

```
┌─────────────────────────────────────┐
│   Presentation Layer (Godot Nodes) │
│   Tank3D, Bullet3D, Camera3D       │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Adapter Layer (Bridge)            │
│   Syncs domain state ↔ presentation │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Domain Layer (Pure Logic)         │
│   No Godot dependencies             │
│   Frame-based, deterministic        │
└─────────────────────────────────────┘
```

**Key Benefits:**

- GaTesting

The project has comprehensive test coverage using BDD (Behavior-Driven Development):

```bash
# Run all tests (375 tests)
make test

# Run domain tests only (366 tests - pure game logic)
make test SUITE=domain

# Run integration tests only (9 tests)
make test SUITE=integration

# Run specific tests by pattern
make test PATTERN=test_tank

# Validate entire project
make validate
```

**Test Statistics:**

- ✅ 375 tests passing (100%)
- 366 domain tests (pure logic, no Godot)
- 9 integration tests (adapter + presentation)
- BDD style: `test_given_X_when_Y_then_Z()`

📖 See [docs/TESTING.md](docs/TESTING.md) for complete testing guide

### Common Commands

```bash
# Development
make edit                 # Open project in Godot
make demo3d              # Play 3D demo scene
make clean               # Clean temporary files

# Testing
make test                # Run all tests
make test SUITE=domain   # Domain tests only
make validate            # Full validation

# Utilities
make help                # Show all commands
```

### Writing Domain Logic

Domain code is pure GDScript (no Godot dependencies):

```gdscript
# src/domain/entities/tank_entity.gd
class_name TankEntity extends RefCounted  # NOT Node!

var position: Position  # Value object (tile coordinates)
var direction: Direction  # NORTH, SOUTH, EAST, WEST
var health: Health

func move(new_position: Position) -> void:
    position = new_position

func take_damage(amount: int) -> bool:
    return health.decrease(amount)
```

### Adding Features (TDD)

1. **Write test first** (Red):
   ```bash
   # tests/domain/test_new_feature.gd
   make test SUITE=domain PATTERN=test_new_feature
   # Test fails irst (TDD): `make test PATTERN=test_new_feature`
   ```
2. Implement the feature in `src/domain/`
3. Ensure all tests pass: `make validate`
4. Commit: `git commit -m 'feat: add amazing feature'`
5. Push: `git push origin feature/amazing-feature`
6. Open a Pull Request

**Code Guidelines:**

- Follow DDD principles (see [docs/DDD_ARCHITECTURE.md](docs/DDD_ARCHITECTURE.md))
- Write tests before implementation (TDD)
- Keep domain layer pure (no Godot dependencies)
- Use BDD test naming: `test_given_X_when_Y_then_Z()`es/new_feature.gd
  make test SUITE=domain PATTERN=test_new_feature

  # Test passes ✅

  ```

  ```

3. **Refactor and validate**:
   ```bash
   make validate
   # All tests pass ✅
   3. Click "Run All" or select specific test files
   ```

Or run from command line:

```bash
godot --headless -s addons/gut/gut_cmdln.gd
```

### Testing Philosophy

- **BDD Style:** Given-When-Then test structure
- **70% Unit / 20% Integration / 10% E2E** split
- Tests use descriptive names: `test_given_X_when_Y_then_Z()`

### Event System

The game uses a centralized event bus for deterministic gameplay:

````gdscript
# Emit events
var event = InputEvent.create_fire()
EventBus.emit_game_event(event)

# Subscribe to events
EventBus.subscribe("Input", _on_input)

# Recording/Replay
EventBus.start_recording(seed)
# .Documentation

- [DDD Architecture](docs/DDD_ARCHITECTURE.md) - Domain-Driven Design principles
- [Testing Guide](docs/TESTING.md) - Comprehensive testing documentation
- [BDD Test Strategy](docs/BDD_TEST_STRATEGY.md) - Testing philosophy
- [Adapter Architecture](docs/ADAPTER_ARCHITECTURE.md) - Layer communication
- [MVP Specification](Tank%201990%20-%20MVP%20Specification.md) - Product requirements

## Roadmap

- [x] DDD architecture implementation
- [x] Domain layer (pure game logic)
- [x] 3D rendering system
- [x] Comprehensive test suite (375 tests - 100%)
- [x] Makefile automation
- [x] Core gameplay mechanics (combat, spawning, scoring)
- [ ] 35 stage designs
- [ ] Audio system
- [ ] Complete stage progression
- [ ] Mobile UI/controls
- [ ] Multiplayer support (future)
- **Space / Enter:** Fire
- **P / Escape:** Pause

### Mobile

- Virtual D-pad (left side)
- Fire button (right side)

## Building

### Desktop

```bash
# Export from Godot Editor or:
godot --headless --export-release "Windows Desktop" builds/tank1990.exe
godot --headless --export-release "macOS" builds/tank1990.dmg
godot --headless --export-release "Linux" builds/tank1990.x86_64
````

### Mobile

Configure export presets in Godot for Android/iOS, then export via editor.

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Write tests for your changes
4. Implement the feature
5. Ensure all tests pass
6. Commit: `git commit -m 'Add amazing feature'`
7. Push: `git push origin feature/amazing-feature`
8. Open a Pull Request

## License

MIT License - see LICENSE file for details

## Acknowledgments

- Original game by Namco (1990)
- Built with [Godot Engine](https://godotengine.org/)
- Testing framework: [GUT](https://github.com/bitwes/Gut)

## Roadmap

- [x] Event system architecture
- [x] Project structure and tooling
- [ ] Core gameplay mechanics
- [ ] 35 stage designs
- [ ] Audio system
- [ ] Mobile UI/controls
- [ ] Leaderboard integration
- [ ] Multiplayer support (future)
