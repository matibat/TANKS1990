# Tank 1990 - Godot Remake

Classic NES Tank 1990 (Battle City) remake built with Godot 4.5+ for desktop and mobile platforms.

## Features

- **Faithful Remake:** Core tank combat mechanics from the NES original
- **Cross-Platform:** Desktop (Windows, macOS, Linux) and Mobile (iOS, Android)
- **Event-Driven Architecture:** Deterministic replay system for game sessions
- **35 Stages:** Progressive difficulty with varied terrain layouts
- **Modern Controls:** Keyboard, gamepad, and touch support

## Setup

### Prerequisites

- Godot 4.5 or later
- Git

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

3. Open the project in Godot:
   - Launch Godot
   - Click "Import"
   - Navigate to the project folder
   - Select `project.godot`

## Project Structure

```
TANKS1990/
├── src/
│   ├── autoload/          # Singleton systems (EventBus)
│   ├── events/            # Event type definitions
│   ├── entities/          # Game entities (tanks, bullets)
│   └── systems/           # Game systems (spawner, collision)
├── scenes/                # Godot scene files
├── resources/
│   ├── stages/           # Stage layout data (JSON)
│   ├── audio/            # Sound effects and music
│   └── sprites/          # Pixel art assets
├── tests/
│   ├── unit/             # Unit tests (BDD style)
│   └── integration/      # Integration tests
└── addons/
    └── gut/              # GUT testing framework (submodule)
```

## Development

### Running Tests

Tests use the GUT (Godot Unit Test) framework:

1. Open project in Godot
2. Go to **Project → Tools → GUT**
3. Click "Run All" or select specific test files

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

```gdscript
# Emit events
var event = InputEvent.create_fire()
EventBus.emit_game_event(event)

# Subscribe to events
EventBus.subscribe("Input", _on_input)

# Recording/Replay
EventBus.start_recording(seed)
# ... gameplay ...
var replay = EventBus.stop_recording()
replay.save_to_file("user://replay.tres")
```

## Controls

### Keyboard

- **WASD / Arrow Keys:** Move
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
```

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
