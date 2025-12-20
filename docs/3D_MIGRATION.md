# TANKS1990 2D-to-3D Migration Documentation

## Overview

This document tracks the migration of TANKS1990 from a 2D to 3D implementation while maintaining deterministic gameplay, test coverage, and event-driven architecture.

**Migration Start Date:** 2025-12-20  
**Godot Version:** 4.5  
**Test Framework:** GUT (Godot Unit Test)

---

## Phase 1: Foundation & Project Setup

### 1.1 Project Configuration

**Physics Settings:**
- `physics_ticks_per_second`: 60 (fixed timestep for determinism)
- `physics_jitter_fix`: 0.0 (disabled for deterministic collisions)

**3D Physics Layers:**
1. **Player** - Player tank entities
2. **Enemies** - Enemy tank entities  
3. **Projectiles** - Bullets and projectile objects
4. **Environment** - Walls, obstacles, terrain
5. **Base** - Home base structure
6. **PowerUps** - Power-up collectibles

### 1.2 Coordinate System

**2D Coordinate System (Legacy):**
- Origin: Top-left corner
- X-axis: Right (positive)
- Y-axis: Down (positive) - screen space convention
- Units: Pixels
- Tile size: 32x32 pixels
- Grid: 26x26 tiles (832x832 world)

**3D Coordinate System (Target):**
- Origin: World center or bottom-left
- X-axis: Right (positive)
- Y-axis: Up (positive) - standard 3D world space
- Z-axis: Forward (negative) or Back (positive) - depends on camera orientation
- Units: Meters (1 unit = 1 meter)
- Ground Plane: Y = 0
- Tile size: 1x1 units (scale factor 1:32 from 2D pixels)

**Conversion Notes:**
```gdscript
# 2D to 3D position conversion
func convert_2d_to_3d(pos_2d: Vector2) -> Vector3:
    return Vector3(
        pos_2d.x / 32.0,  # X: pixels to units
        0.0,               # Y: ground level
        pos_2d.y / 32.0   # Z: Y-down becomes Z-forward/back
    )

# 3D to 2D position conversion (for compatibility/debugging)
func convert_3d_to_2d(pos_3d: Vector3) -> Vector2:
    return Vector2(
        pos_3d.x * 32.0,  # X: units to pixels
        pos_3d.z * 32.0   # Z: becomes Y-down
    )
```

### 1.3 Directory Structure

**New Directories:**
- `scenes3d/` - 3D scene files (parallel to `scenes/`)
- `resources/meshes3d/` - 3D mesh generators and materials
- `resources/models/` - (future) Imported 3D models

**Maintained Directories:**
- `scenes/` - Original 2D scenes (preserved during migration)
- `src/` - Shared game logic (dimension-agnostic)
- `tests/` - Test suites (expanded for 3D)

### 1.4 Architecture Decisions

**Decision 1: Parallel Scene Structure**
- Rationale: Keep 2D scenes intact during migration for A/B testing and rollback
- Impact: Allows gradual migration; can run 2D and 3D versions side-by-side
- Files: `scenes/` (2D) and `scenes3d/` (3D)

**Decision 2: Shared Game Logic**
- Rationale: Core systems (EventBus, managers, controllers) are dimension-agnostic
- Impact: Minimal duplication; logic tested once, used in both 2D and 3D
- Requirement: EventBus must support both Vector2 and Vector3 serialization

**Decision 3: Maintain Determinism**
- Rationale: Event replay, network sync, and testing depend on deterministic behavior
- Impact: All 3D physics must use fixed timestep, quantized positions, seeded RNG
- Tools: Vector3 quantization helpers, fixed 60 Hz tick rate

**Decision 4: Test-Driven Development**
- Rationale: Preserve 305/311 passing tests; validate every change
- Impact: Write tests before implementation; run `make test-unit` after each step
- Coverage Target: 100% for new 3D utilities

---

## Phase 1 Deliverables

### Completed:
- [x] Git tag `v1.0-2d-stable` created for rollback
- [x] project.godot: 3D physics layers configured
- [x] project.godot: physics_ticks_per_second = 60
- [x] `scenes3d/` directory structure created
- [x] `resources/meshes3d/` directory structure created
- [x] 3D_MIGRATION.md documentation started
- [x] EventBus: Vector3 serialization support implemented (TDD)
- [x] Vector3 helper utilities created with 100% test coverage
- [x] GUT 3D compatibility verified with 13 passing tests

### Acceptance Criteria:
- [x] All existing tests pass (324/330 passing - same 6 pending as baseline)
- [x] `make check-compile` passes (0 compilation errors)
- [x] New 3D utilities have 100% test coverage
- [x] No regressions in 2D functionality

### Test Summary:
**Unit Tests:** 324/330 passing (55 test scripts)
- EventBus Vector3 serialization: 5/5 tests ✅
- Vector3 quantization helpers: 5/5 tests ✅
- Vector3 approximate equality: 7/7 tests ✅
- Vector3 determinism validation: 2/2 tests ✅

**Integration Tests:** 13/13 3D compatibility tests ✅
- Node3D instantiation: 2/2 ✅
- Vector3 operations: 3/3 ✅
- 3D hierarchy: 2/2 ✅
- Collision shapes: 2/2 ✅
- MeshInstance3D: 2/2 ✅
- Camera3D: 2/2 ✅

**Phase 1 Status:** ✅ **COMPLETE**

---

## Testing Strategy

### Unit Tests:
- EventBus Vector3 serialization: `tests/unit/test_event_bus.gd`
- Vector3 helpers: `tests/unit/test_vector3_helpers.gd`

### Integration Tests:
- 3D scene compatibility: `tests/integration/test_3d_compatibility.gd`
- 3D camera/environment: `tests/integration/test_3d_camera_environment.gd`

### Validation Commands:
```bash
make check-compile   # GDScript syntax/type checking
make test-unit       # Run all unit tests
make test-integration # Run integration tests
```

---

## Known Issues & Risks

**Risk 1: Physics Determinism in 3D**
- Concern: Godot 3D physics may have floating-point variations
- Mitigation: Quantize all Vector3 positions, use fixed timestep, extensive testing

**Risk 2: Test Coverage Gap**
- Concern: Some 2D tests may not translate to 3D
- Mitigation: Write 3D-specific tests in parallel; maintain > 95% coverage

**Risk 3: Performance Impact**
- Concern: 3D rendering may affect performance on low-end devices
- Mitigation: Profile early, optimize rendering, maintain 60 FPS target

---

## Next Phases (Planned)

**Phase 2:** 3D Scene Graph & Entities
- Convert Node2D to Node3D hierarchy
- Implement 3D tank entities with MeshInstance3D
- 3D collision shapes and physics bodies

**Phase 3:** 3D Camera & Rendering
- Top-down orthographic camera (matches 2D feel)
- Lighting setup for visibility
- Material/shader system for retro aesthetic

**Phase 4:** 3D Terrain & Environment
- Tile-based 3D level generation
- Wall and obstacle collision
- Base structure 3D model

**Phase 5:** Integration & Testing
- Complete 3D gameplay loop
- Replay system validation with 3D
- Performance profiling and optimization

---

## References

- Godot 3D Physics: https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html
- GUT Testing Framework: https://github.com/bitwes/Gut
- Deterministic Physics: See `docs/knowledge_base/2d-to-3d-godot-migration.md`
