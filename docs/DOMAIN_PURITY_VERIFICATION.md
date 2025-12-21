# Domain Layer Purity Verification

## Overview

The domain layer purity verification script ensures complete decoupling between the domain layer and Godot engine, maintaining clean Domain-Driven Design (DDD) architecture.

## Quick Start

```bash
# Verify domain layer purity
make verify-domain

# Or run directly
bash scripts/verify_domain_purity.sh
```

## What It Checks

### ❌ Forbidden Patterns (Godot Coupling)

The script detects and reports violations of domain purity:

1. **Node Inheritance**
   - `extends Node`, `extends Node2D`, `extends Node3D`
   - `extends Control`, `extends Resource`
   
2. **Godot Annotations**
   - `@export` - exposes variables to editor
   - `@onready` - deferred initialization

3. **Node References**
   - `$NodePath` - node path syntax
   - `get_node()` - node tree access
   - `get_tree()` - scene tree access

4. **Scene/Resource Loading**
   - `load("res://...tscn")` - scene files
   - `preload("res://...tscn")` - scene preloading
   - `load("res://...tres")` - resource files
   - `preload("res://...tres")` - resource preloading

5. **Singleton Access**
   - `Engine.` - engine singleton
   - `OS.` - operating system singleton

### ✅ Allowed Patterns (Pure Domain)

Domain classes should use:

1. **RefCounted Inheritance**
   ```gdscript
   class_name MyDomainClass
   extends RefCounted
   ```

2. **Value Objects**
   ```gdscript
   const Position = preload("res://src/domain/value_objects/position.gd")
   var position: Position
   ```

3. **Pure Logic**
   - No visual representation
   - No scene tree dependencies
   - No Godot engine coupling
   - Only business logic

## Output Examples

### Clean Domain Layer
```
=== Domain Layer Purity Verification ===

Checking: src/domain/

Scanning domain files...

✅ src/domain/entities/tank_entity.gd
✅ src/domain/services/collision_service.gd
✅ src/domain/value_objects/position.gd

=========================================
Summary:
  Total files checked: 39
  Files with violations: 0
  Total violations: 0

✅ Domain layer is pure! No Godot coupling detected.
```

### Violations Detected
```
❌ src/domain/test_violation.gd
   Line 4: Godot @export annotation
   └─> @export var test_value: int = 5
   Line 7: Godot get_node() call
   └─> var node = get_node("SomePath")

=========================================
Summary:
  Total files checked: 40
  Files with violations: 1
  Total violations: 2

❌ Domain layer has Godot coupling violations!
```

## Architecture Principles

### Why Domain Purity Matters

1. **Testability**: Pure domain logic can be tested without Godot engine
2. **Portability**: Domain code could be reused in different engines
3. **Maintainability**: Clear separation of concerns
4. **Performance**: No scene tree overhead in business logic

### DDD Layer Structure

```
src/
├── domain/              # ✅ Pure GDScript (verified by this script)
│   ├── entities/       # Business objects
│   ├── value_objects/  # Immutable data
│   ├── services/       # Business logic
│   ├── aggregates/     # State containers
│   └── events/         # Domain events
│
├── application/         # Use cases & command handlers
└── presentation/        # ❌ Godot coupling allowed here
    └── adapters/       # Maps domain to Godot nodes
```

## Integration with CI/CD

Add to your continuous integration pipeline:

```yaml
# .github/workflows/test.yml
- name: Verify Domain Purity
  run: make verify-domain
```

## Current Status

**Last Verification**: December 21, 2025

- ✅ All 39 domain files verified
- ✅ Zero Godot coupling violations
- ✅ Complete domain/presentation separation

## Files Scanned

The script automatically checks all `.gd` files in:
- `src/domain/entities/`
- `src/domain/value_objects/`
- `src/domain/services/`
- `src/domain/aggregates/`
- `src/domain/events/`
- `src/domain/commands/`
- `src/domain/constants/`
- Root domain files (`game_loop.gd`, `game_state_machine.gd`)

## Maintenance

To add new forbidden patterns, edit [scripts/verify_domain_purity.sh](../scripts/verify_domain_purity.sh):

```bash
# Add to pattern_checks array
declare -a pattern_checks=(
    'your_pattern|Description of violation'
    # ... existing patterns
)
```

## Related Documentation

- [DDD Architecture](DDD_ARCHITECTURE.md)
- [Testing Strategy](TESTING.md)
- [Adapter Architecture](ADAPTER_ARCHITECTURE.md)

## Task Context

This script was created as part of Task 4 from the refactoring plan to ensure domain layer maintains zero Godot coupling while implementing grid-based collision detection.

See: `/tmp/task_plan.md` (Task 4)
