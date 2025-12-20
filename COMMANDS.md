# TANKS1990 - Commands & Cheatsheet

Quick reference for developers working on the TANKS1990 3D migration.

## Table of Contents
- [Development Commands](#development-commands)
- [Testing](#testing)
- [3D Migration Status](#3d-migration-status)
- [Godot Editor](#godot-editor)
- [Git Workflow](#git-workflow)
- [Troubleshooting](#troubleshooting)

---

## Development Commands

### Testing Commands

```bash
# Quick compile check (runs first, catches syntax errors)
make check-compile

# Run all tests
make test

# Run specific test categories
make test-unit           # Unit tests only (~400 tests)
make test-integration    # Integration tests (~100 tests)
make test-performance    # Performance benchmarks (~13 tests)

# Run a specific test file
make test-file FILE=res://tests/unit/test_tank3d.gd

# Validate everything (compile + all tests)
make validate
```

### 3D Demo Commands

```bash
# Open the 3D demo scene in Godot (SEE THE 3D GAME!)
make demo3d

# Open project in Godot editor
make edit
```

### Utility Commands

```bash
# Clean temporary files
make clean

# Show all available commands
make help
```

---

## Testing

### Test Structure

```
tests/
├── unit/                  # 400+ tests - individual classes/functions
│   ├── test_tank3d.gd    # Tank entity tests
│   ├── test_bullet3d.gd  # Bullet entity tests
│   ├── test_base3d.gd    # Base entity tests
│   └── ...
├── integration/           # 100+ tests - components working together
│   ├── test_tank_collisions.gd
│   ├── test_bullet_collisions.gd
│   └── ...
└── performance/           # 13 tests - frame time budgets
    └── test_physics_performance.gd
```

### Test Categories

| Category | Count | Focus | Target |
|----------|-------|-------|--------|
| **Unit** | ~400 | Individual classes | <1ms each |
| **Integration** | ~100 | Component interaction | <10ms each |
| **Performance** | ~13 | Frame budgets | <5ms physics |

### Writing Tests

All tests use GUT (Godot Unit Test) framework:

```gdscript
extends GutTest

func test_tank_spawns_at_correct_position():
    # Arrange
    var tank = preload("res://scenes3d/player_tank3d.tscn").instantiate()
    add_child(tank)
    tank.position = Vector3(5, 0, 5)
    
    # Act
    await get_tree().process_frame
    
    # Assert
    assert_almost_eq(tank.position.x, 5.0, 0.01, "Tank X position")
    assert_almost_eq(tank.position.z, 5.0, 0.01, "Tank Z position")
```

### Test-Driven Development (TDD)

**Golden Rule:** Write tests BEFORE implementing features.

```bash
# 1. Write the test (it will fail)
# tests/unit/test_new_feature.gd

# 2. Run the test to confirm it fails
make test-file FILE=res://tests/unit/test_new_feature.gd

# 3. Implement the feature
# src/entities/new_feature.gd

# 4. Run the test again (it should pass)
make test-file FILE=res://tests/unit/test_new_feature.gd

# 5. Run all tests to ensure no regressions
make validate
```

---

## 3D Migration Status

### ✅ Completed (Phases 1-6)

| Component | Status | Location |
|-----------|--------|----------|
| **Foundation** | ✅ Complete | Phase 1 |
| **Camera & Lighting** | ✅ Complete | Phase 2 |
| **Visual Assets** | ✅ Complete | Phase 3 |
| **Tank Entity** | ✅ Complete | Phase 4 |
| **Bullet & Base** | ✅ Complete | Phase 5 |
| **Physics & Collision** | ✅ Complete | Phase 6 |

### 🔧 What Works Now

- ✅ 3D Tank entities (CharacterBody3D)
- ✅ 3D Bullets (Area3D)
- ✅ 3D Base (StaticBody3D)
- ✅ Top-down orthogonal camera
- ✅ Collision detection (tank-tank, bullet-entity, bullet-wall)
- ✅ Deterministic physics (quantized Vector3)
- ✅ Low-poly meshes (<500 tris per entity)
- ✅ 800+ tests (95%+ passing)

### 🚧 In Progress (Phases 7-10)

| Phase | Status | Description |
|-------|--------|-------------|
| **7: Terrain** | 🚧 Planned | 26×26 grid, destructible walls |
| **8: Game Systems** | 🚧 Planned | Power-ups, game flow, UI |
| **9: Test Migration** | 🚧 Planned | Full 2D→3D test coverage |
| **10: Polish** | 🚧 Planned | Performance, effects, cross-platform |

### Viewing the 3D Game

```bash
# Method 1: Run demo scene
make demo3d

# Method 2: In Godot editor
# 1. Open project: make edit
# 2. Open scenes3d/demo3d.tscn
# 3. Press F5 (Run Current Scene)

# What you'll see:
# - Top-down 3D camera
# - Yellow player tank (center)
# - Green enemy tanks (corners)
# - Eagle base (bottom)
# - 26×26 grid floor
```

---

## Godot Editor

### Opening Scenes

```bash
# Open specific scene
godot scenes3d/demo3d.tscn

# Open project in editor
godot -e project.godot

# Using make commands
make demo3d  # Opens demo scene
make edit    # Opens editor
```

### Running Tests in Editor

1. Open Godot editor: `make edit`
2. Bottom panel: Click "GUT" tab
3. Select test directory (e.g., `res://tests/unit`)
4. Click "Run All"

### Scene Locations

```
scenes/          # 2D scenes (original game)
├── main.tscn
├── player_tank.tscn
└── enemy_tank.tscn

scenes3d/        # 3D scenes (migration)
├── demo3d.tscn           # ⭐ Playable 3D demo
├── game_root3d.tscn      # 3D game root
├── player_tank3d.tscn    # 3D player tank
├── enemy_tank3d.tscn     # 3D enemy tank
├── bullet3d.tscn         # 3D bullet
├── base3d.tscn           # 3D base
├── camera_3d.tscn        # Orthogonal camera
├── game_lighting.tscn    # DirectionalLight3D
├── ground_plane.tscn     # 26×26 grid floor
└── world_environment.tscn
```

---

## Git Workflow

### Current Branch Status

```bash
# Check status
git status

# View migration commits
git log --oneline --grep="Phase"

# View 3D migration tags
git tag -l "v1.*-3d-*"
```

### Key Commits

| Commit | Description |
|--------|-------------|
| `v1.0-2d-stable` | 2D game baseline (before migration) |
| Phase 1 | Foundation & Vector3 support |
| Phase 2 | Camera & environment |
| Phase 3 | Visual assets & meshes |
| Phase 4 | Tank entity migration |
| Phase 5 | Bullet & Base migration |
| Phase 6 | Physics & collision |
| `cb59b30` | Critical fix: Created missing scene files |

### Rolling Back

```bash
# Return to stable 2D version
git checkout v1.0-2d-stable

# Return to latest
git checkout main
```

---

## Troubleshooting

### Compile Errors

```bash
# Always run this first
make check-compile

# Common issues:
# - Missing semicolons
# - Undefined variables
# - Type mismatches (Vector2 vs Vector3)
```

### Test Failures

```bash
# Run specific failing test for details
make test-file FILE=res://tests/unit/test_example.gd

# Common issues:
# - Missing `await get_tree().process_frame` for scene instantiation
# - Incorrect Vector3 quantization
# - Collision layers misconfigured
```

### 3D Not Showing

```bash
# Verify scene files exist
ls scenes3d/*.tscn

# Required scenes:
# - player_tank3d.tscn
# - bullet3d.tscn
# - base3d.tscn
# - demo3d.tscn

# If missing, check git status
git status scenes3d/
```

### Performance Issues

```bash
# Run performance benchmarks
make test-performance

# Check frame budgets:
# - Physics: <5ms per frame (target)
# - Single tank: <0.1ms
# - 20 tanks: <5ms
```

### Godot Won't Start

```bash
# Check Godot installation
which godot
godot --version  # Should be 4.5.1 or higher

# Set custom Godot path
export GODOT=/path/to/godot
make check-compile
```

---

## "Cheatcodes" (Developer Shortcuts)

### Quick Iteration Loop

```bash
# 1. Make changes to code
# 2. Check syntax immediately
make check-compile

# 3. Run relevant tests
make test-file FILE=res://tests/unit/test_your_feature.gd

# 4. See visual changes
make demo3d
```

### Test-Specific Entity

```bash
# Test just tank behavior
make test-file FILE=res://tests/unit/test_tank3d.gd

# Test just bullet behavior  
make test-file FILE=res://tests/unit/test_bullet3d.gd

# Test just collisions
make test-file FILE=res://tests/integration/test_tank_collisions.gd
```

### Skip Long Test Runs

```bash
# During development, focus on unit tests (fast)
make test-unit

# Save integration/performance for pre-commit
make test-integration
make test-performance
```

### Find Specific Test

```bash
# Search test files by name
find tests -name "*tank*.gd"

# Search test content
grep -r "test_movement" tests/
```

### View Test Coverage

```bash
# Run all tests and check pass rate
make test | grep "Passing Tests"

# Expected: 95%+ pass rate
# Current: ~800 tests, ~760+ passing
```

---

## Quick Reference

### Most Used Commands

```bash
make check-compile    # Fast syntax check
make demo3d           # See 3D game
make test-unit        # Run unit tests
make validate         # Full validation
make help             # Show all commands
```

### File Patterns

```bash
# 2D (original)
scenes/*.tscn
src/entities/*.gd (extends CharacterBody2D, Area2D)

# 3D (migration)
scenes3d/*.tscn
src/entities/*3d.gd (extends CharacterBody3D, Area3D)
```

### Collision Layers (Bitmask)

| Layer | Name | Value | Entities |
|-------|------|-------|----------|
| 1 | Player | 1 | Player tank |
| 2 | Enemy | 2 | Enemy tanks |
| 3 | Projectiles | 4 | Bullets |
| 4 | Environment | 8 | Walls, terrain |
| 5 | Base | 16 | Eagle base |
| 6 | PowerUp | 32 | Power-up items |

---

## Additional Resources

- [docs/3D_MIGRATION.md](docs/3D_MIGRATION.md) - Full migration technical details
- [docs/3D_TESTING_GUIDE.md](docs/3D_TESTING_GUIDE.md) - Testing methodology
- [docs/3D_ASSET_SPECS.md](docs/3D_ASSET_SPECS.md) - Visual asset specifications
- [CRITICAL_FIX_REPORT.md](CRITICAL_FIX_REPORT.md) - Recent scene file fix

---

**Last Updated:** December 20, 2025  
**Godot Version:** 4.5.1  
**Test Framework:** GUT 9.5.0
