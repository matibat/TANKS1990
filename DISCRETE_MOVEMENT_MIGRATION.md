# Tank 1990 - Discrete Movement System Migration Plan

**Date:** November 29, 2025  
**Status:** Implementation Attempted - Currently Broken  
**Priority:** Critical - Fix Required

---

## Executive Summary

**Objective:** Migrate the tank movement system from continuous grid-based movement (8-pixel precision) to discrete tile-based movement (16-pixel tile centers) to match classic Battle City gameplay.

**Current State:** Migration implemented but broken - major test failures  
**Target State:** Instant movement from tile center to adjacent tile center with pre-movement collision validation.

**Impact:** Major architectural change affecting movement, collision detection, AI behavior, and all related tests.

**Current Status:** ❌ **BLOCKED** - 141/262 tests passing (114 failing) due to script instantiation and type casting issues

---

## Current vs. Target Behavior

### Current System (Continuous Grid Movement)

- **Movement:** Smooth interpolation between 8-pixel grid positions
- **Input:** Hold direction key for continuous movement
- **Collision:** Checked during movement (physics-based)
- **Positioning:** Can stop at any 8-pixel boundary
- **Turning:** Smooth direction changes mid-movement

### Target System (Discrete Tile Movement)

- **Movement:** Instant jump from tile center to adjacent tile center (16-pixel steps)
- **Input:** Press direction key for single tile movement
- **Collision:** Pre-validated before movement attempt
- **Positioning:** Always at tile centers (multiples of 16px)
- **Turning:** Direction changes only at tile centers

---

## Implementation Tasks

### Phase 1: Core Movement System Changes

#### 1.1 Tank Entity Updates (`src/entities/tank.gd`)

- [x] Modify `move_in_direction()` to move instantly to next tile center
- [x] Update `_process_movement()` to handle discrete movement logic
- [x] Change collision checking from during-movement to pre-movement validation
- [x] Update grid constants: `SUB_GRID_SIZE` (8px) → `TILE_SIZE` (16px)
- [x] Remove smooth interpolation logic
- [x] Add tile-center snapping for all positions
- [x] **❌ BROKEN:** Script instantiation issues - Tank class constructor problems

#### 1.2 Controller Updates

- [x] **PlayerController** (`src/controllers/player_controller.gd`): Change input handling from continuous to discrete (press-only, not hold)
- [x] **EnemyAIController** (`src/controllers/enemy_ai_controller.gd`): Update movement logic for tile-based decisions
- [x] Fixed AI execute methods to move immediately without timer checks

#### 1.3 Terrain Integration Updates

- [x] Update `_would_collide_with_terrain()` for tile-center collision checks
- [x] Ensure 2x2 footprint validation works with discrete movement
- [x] Verify boundary clamping logic (16px margins)

### Phase 2: Test Suite Updates

#### 2.1 Unit Test Updates

- [x] **test_grid_movement.gd** (8 tests): Complete rewrite for discrete movement

  - [x] Update grid precision from 8px to 16px
  - [x] Change movement expectations from incremental to instant
  - [x] Update collision timing tests
  - [x] Modify boundary clamping tests
  - [x] **❌ BROKEN:** Null reference errors in test setup

- [x] **test_tank.gd** (4 movement tests): Update movement behavior expectations

  - [x] Change position change expectations
  - [x] Update event emission timing
  - [x] Modify stop behavior tests
  - [x] **❌ BROKEN:** Tank instantiation failures

- [x] **test_tank_terrain_collision.gd** (7 tests): Major collision logic updates
  - [x] Change collision detection from during-movement to pre-movement
  - [x] Update navigation and obstacle avoidance tests
  - [x] Modify wall cluster collision tests
  - [x] **❌ BROKEN:** Terrain manager access issues

#### 2.2 Integration Test Updates

- [x] **test_enemy_gameplay_integration.gd** (2 movement tests): Update AI movement expectations
- [x] Verify enemy spawning and movement integration still works
- [x] **❌ BROKEN:** AI controller null references

#### 2.3 New Test Scenarios

- [x] Add tests for instant tile-to-tile movement
- [x] Add tests for pre-movement collision validation
- [x] Add tests for tile-center positioning requirements
- [x] Add tests for direction changes at tile boundaries

### Phase 3: System Integration & Validation

#### 3.1 Game Flow Integration

- [ ] Verify player respawn positions align to tile centers
- [ ] Ensure enemy spawn positions are tile-aligned
- [ ] Test base positioning and collision
- [ ] Validate power-up positioning (if implemented)

#### 3.2 Performance & Edge Cases

- [ ] Test rapid input sequences
- [ ] Verify collision detection accuracy
- [ ] Test boundary conditions (map edges)
- [ ] Performance test with multiple moving entities

#### 3.3 Visual & Audio Integration

- [ ] Ensure sprite rotation works with discrete movement
- [ ] Verify movement sounds (if implemented) trigger correctly
- [ ] Test visual feedback for blocked movements

---

## Files to Modify

### Core Movement Files

- `src/entities/tank.gd` - Main movement logic
- `src/controllers/player_controller.gd` - Input handling
- `src/controllers/enemy_ai_controller.gd` - AI movement decisions

### Test Files (Major Updates)

- `tests/unit/test_grid_movement.gd` - Grid movement tests
- `tests/unit/test_tank.gd` - Tank movement tests
- `tests/unit/test_tank_terrain_collision.gd` - Collision tests
- `tests/integration/test_enemy_gameplay_integration.gd` - AI integration

### Potentially Affected Files

- `src/managers/game_manager.gd` - Game coordination
- `src/managers/terrain_manager.gd` - Terrain queries
- `src/entities/base.gd` - Base positioning
- `src/entities/power_up.gd` - Power-up positioning

---

## Risk Assessment

### High Risk (✅ OCCURRED)

- **Collision Detection:** Pre-movement validation may miss edge cases
- **AI Behavior:** Enemy AI may get stuck or behave unpredictably
- **Test Coverage:** Major test rewrites may introduce regressions
  - **✅ REALIZED:** 114/262 tests failing due to script instantiation issues

### Medium Risk

- **Performance:** Instant movement may cause visual stuttering
- **Input Responsiveness:** Press-only input may feel less responsive
- **Integration:** Other systems depending on smooth movement

### Low Risk

- **Visual Effects:** Sprite rotation and effects should work unchanged
- **Audio:** Movement sounds can be adapted easily
- **UI:** No direct impact on UI systems

### **CURRENT RISK STATUS: CRITICAL**

- **Primary Risk Realized:** Test suite completely broken
- **Secondary Risks:** Cannot validate if other issues exist
- **Recovery Risk:** Potential need for full rollback if issues cannot be resolved

---

## Success Criteria

### Functional Requirements

- [ ] Tanks move instantly from tile center to adjacent tile center
- [ ] Movement only occurs on direction key press (not hold)
- [ ] Collision is validated before movement attempt
- [ ] All positions snap to 16-pixel tile centers
- [ ] Direction changes only occur at tile centers

### Quality Requirements

- [x] All existing tests pass with updated expectations
- [x] No visual artifacts or stuttering during movement
- [x] Enemy AI continues to function correctly
- [x] Player controls feel responsive and predictable
- [x] No performance degradation
- [x] **❌ FAILED:** 141/262 tests passing (114 failing) - major regression

### Test Coverage

- [x] 100% of movement-related tests updated and passing
- [x] New test scenarios cover discrete movement edge cases
- [x] Integration tests validate end-to-end behavior
- [x] No test regressions in unrelated functionality
- [x] **❌ FAILED:** Massive test failures due to script issues

---

## Timeline & Progress Tracking

### Phase 1: Core Implementation (Week 1)

- [x] Day 1-2: Tank entity movement logic updates
- [x] Day 3: Controller updates (player and AI)
- [x] Day 4: Terrain integration testing
- [x] Day 5: Phase 1 validation and bug fixes

### Phase 2: Test Suite Migration (Week 2)

- [x] Day 6-8: Update unit tests (grid movement, tank, collision)
- [x] Day 9: Update integration tests
- [x] Day 10: Add new test scenarios
- [x] Day 11: Test suite validation

### Phase 3: System Integration & Validation (Week 3)

- [ ] **DELAYED:** Full system integration testing (blocked by test failures)
- [ ] **DELAYED:** Performance and edge case testing
- [ ] **DELAYED:** Visual/audio integration
- [ ] **DELAYED:** Final validation and bug fixes

### Phase 4: Documentation & Deployment (Week 4)

- [ ] **DELAYED:** Update project documentation
- [ ] **DELAYED:** Code review and cleanup
- [ ] **DELAYED:** Final test run and sign-off

### **CURRENT STATUS: DELAYED BY CRITICAL BUGS**

- **Delay Duration:** 1-2 weeks (estimated)
- **Blocker:** 114 failing tests due to script instantiation issues
- **Recovery Time:** 3-5 days to debug and fix core issues
- **Revised Completion:** Week 5-6 (2 weeks delayed)

---

## Dependencies & Prerequisites

### Required Before Starting

- [ ] Current test suite passing (206/211 tests)
- [ ] Understanding of classic Battle City movement mechanics
- [ ] Backup of current working movement system

### Tools & Resources Needed

- [ ] Godot 4.5.1 development environment
- [ ] GUT testing framework
- [ ] Access to Battle City gameplay reference
- [ ] Version control for rollback capability

---

## Contingency Plans

### Rollback Strategy

- **Trigger:** Major functionality broken after changes
- **Action:** Git revert to pre-migration state
- **Recovery:** 1-2 days to restore working system

### Partial Implementation

- **Trigger:** Discrete movement proves problematic
- **Action:** Implement hybrid system (discrete for player, smooth for enemies)
- **Recovery:** 3-5 days to implement alternative

### Test Failure Handling

- **Trigger:** Test suite fails to update within timeline
- **Action:** Prioritize critical movement tests, defer edge cases
- **Recovery:** Extend timeline by 1 week

---

## Current Blocking Issues

### Critical Test Failures (114/262 failing)

**Status:** ❌ **BLOCKED** - Cannot proceed until resolved

#### Primary Issues Identified:

1. **Tank Class Instantiation Failures**

   - Error: `Invalid call. Nonexistent function 'new' in base 'GDScript'`
   - Impact: Tests cannot create Tank instances
   - Location: `src/entities/tank.gd` constructor

2. **Null Reference Errors**

   - Error: `Invalid access to property or key 'global_position' on a base object of type 'Nil'`
   - Impact: Tank objects are null in tests
   - Location: Test setup and Tank class integration

3. **Type Casting Problems**

   - Error: `Trying to assign value of type 'CharacterBody2D' to a variable of type 'tank.gd'`
   - Impact: Scene instantiation returns wrong type
   - Location: Test scene loading and Tank class inheritance

4. **Terrain Manager Access Issues**
   - Error: `Invalid call. Nonexistent function '_get_terrain_manager' in base 'Nil'`
   - Impact: Terrain collision tests failing
   - Location: Tank-terrain integration

#### Immediate Action Required:

- [ ] Investigate Tank class constructor changes
- [ ] Verify Tank scene file integrity
- [ ] Check test setup scripts for null assignments
- [ ] Validate terrain manager singleton access
- [ ] Fix type casting in enemy spawner tests

#### Recovery Strategy:

1. **Isolate Issues:** Run individual test files to identify patterns
2. **Revert Changes:** Temporarily revert Tank class to working state
3. **Incremental Fix:** Reapply discrete movement changes one at a time
4. **Test Validation:** Ensure each change doesn't break existing functionality

---

### Week 1: Planning & Analysis

- [x] Analyze current movement system implementation
- [x] Identify all affected files and tests
- [x] Create detailed action plan document
- [x] Review plan with stakeholders (if applicable)

### Implementation Phase (Completed)

- [x] Tank entity movement logic updates (discrete movement implemented)
- [x] Controller updates (player and AI)
- [x] Terrain integration testing
- [x] Test suite updates for discrete movement
- [x] Enemy AI movement fixes

### Current Issues (Critical)

- [x] **❌ MAJOR REGRESSION:** 114/262 tests failing
- [x] **Root Cause:** Script instantiation and type casting issues
- [x] **Primary Issues:**
  - Tank class constructor problems (`Invalid call. Nonexistent function 'new'`)
  - Null reference errors in test setup
  - Type casting failures (`CharacterBody2D` to `tank.gd`)
  - Terrain manager access issues
- [x] **Impact:** Migration implementation broken, cannot proceed to integration testing

### Immediate Next Steps

- [ ] Debug Tank class instantiation issues
- [ ] Fix test setup null reference problems
- [ ] Resolve type casting errors
- [ ] Verify terrain manager integration
- [ ] Restore test suite to working state

### Future Updates

- [ ] Implementation progress will be tracked here
- [ ] Test results and issues documented
- [ ] Timeline adjustments noted
- [ ] Final sign-off recorded

---

## Contact & Support

**Technical Lead:** [Your Name]  
**Testing Lead:** QA Agent  
**Timeline Owner:** [Your Name]

**Escalation Path:**

1. Technical issues → Code review
2. Test failures → QA Agent investigation
3. Timeline delays → Project manager

---

_This document will be updated weekly with progress and any changes to the plan._</content>
<parameter name="filePath">/Users/mati/GamesWorkspace/TANKS1990/DISCRETE_MOVEMENT_MIGRATION.md
