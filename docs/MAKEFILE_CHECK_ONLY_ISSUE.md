# Makefile check-only Issue - Root Cause

## Problem

The `make test` command was hanging during the `check-only` pre-check step. The command `godot --headless --check-only --quit` would load the entire game scene (GameRoot3D, GameCoordinator in MENU state) and never exit.

## Root Cause

The `--check-only` flag is designed to check a **single script file** (see `godot --help`: "Only parse for errors and quit **(use with --script)**"), not validate an entire project.

When the project has:

- `run/main_scene="res://scenes3d/game_3d_ddd.tscn"` in project.godot
- Autoloads (RandomProvider, DebugLogger)

Running `godot --headless --check-only --quit` will:

1. Load all autoloads
2. Load the main scene
3. Initialize the game (GameRoot3D → GameCoordinator)
4. **Hang indefinitely** because the scene is running

## Solution

**Removed the `check-only` target** from the Makefile. Project validation is now handled by:

1. `check-import` - Imports all assets (catches asset errors)
2. `check-compile` - Runs `res://tests/hooks/compile_check.gd` to validate all scripts

## Correct Usage of --check-only

The `--check-only` flag should ONLY be used with `--script` to check a single file:

```bash
# ✅ Correct: Check a single script
godot --headless --check-only --script src/domain/entities/tank_entity.gd

# ❌ Wrong: Try to check entire project (will hang if main_scene is set)
godot --headless --check-only --quit
```

The Makefile's `check-script` and `check-errors` targets use it correctly with `--script FILE`.

## Alternative Approaches Considered

1. **Remove main_scene from project.godot** - Not ideal, as the project needs a main scene to run
2. **Use GODOT_EXPORT_ALL_RESOURCES=1** - Unclear if this actually fixes the issue or was just timing
3. **Implement quiet/verbose logging** - Doesn't solve the hang, just hides the output

The correct solution is to **not use --check-only for project validation** since it's the wrong tool for that job.

## Verification

After removing `check-only` from `precheck`:

```bash
make test SUITE=domain PATTERN=test_tank_entity
# ✅ Completes successfully in ~1s
# Runs: check-import → check-compile → tests
```
