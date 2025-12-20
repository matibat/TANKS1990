# TANKS1990 - 3D Asset Specification

**Date**: December 20, 2025  
**Phase**: 3 - Visual Assets  
**Status**: Design Complete

## Overview

Low-poly, retro arcade aesthetic for TANKS1990 3D conversion. All assets procedurally generated using GDScript ArrayMesh for easy iteration and minimal storage footprint.

## Design Philosophy

- **Retro Arcade Style**: Simple geometric shapes, solid colors, minimal detail
- **Low Triangle Budget**: Mobile-friendly, <800 tris per entity
- **Unlit Rendering**: Flat-shaded solid colors (no textures/lighting calculations)
- **Procedural Generation**: All meshes generated at runtime via GDScript
- **Match 2D Hitboxes**: 3D dimensions correspond to 2D collision areas

## Performance Budget

### Triangle Counts (Target)

| Entity Type       | Triangle Budget | Notes                                           |
| ----------------- | --------------- | ----------------------------------------------- |
| Player Tank       | ~500 tris       | Body (200) + Turret (150) + Treads (150)        |
| Enemy Tank Type 1 | ~300 tris       | Basic (simpler than player)                     |
| Enemy Tank Type 2 | ~300 tris       | Light variant                                   |
| Enemy Tank Type 3 | ~300 tris       | Heavy variant                                   |
| Enemy Tank Type 4 | ~300 tris       | Fast variant                                    |
| Base/Eagle        | ~300 tris       | Iconic structure with detail                    |
| Bullet            | ~50 tris        | Simple projectile (16-24 sides sphere/cylinder) |
| Power-Up Star     | ~100 tris       | Rotating star shape                             |
| Power-Up Helmet   | ~100 tris       | Shield icon                                     |
| Power-Up Clock    | ~100 tris       | Time freeze icon                                |
| Power-Up Shovel   | ~100 tris       | Base protection icon                            |
| Power-Up Grenade  | ~100 tris       | Screen clear icon                               |
| Power-Up Tank     | ~100 tris       | Extra life icon                                 |
| Brick Wall Tile   | ~12 tris        | Simple cube (2 tris × 6 faces)                  |
| Steel Wall Tile   | ~12 tris        | Cube with metallic appearance                   |
| Water Tile        | ~12 tris        | Flat animated surface                           |
| Forest Tile       | ~100 tris       | Simple trees/vegetation                         |

### Total Scene Budget

- **Simultaneous entities**: ~20-30 (player + enemies + bullets + power-ups)
- **Terrain**: 26×26 grid = 676 tiles (mostly bricks/steel at ~12 tris each = ~8k tris)
- **Estimated peak**: 8k (terrain) + 20×400 (entities) = ~16k tris
- **Target**: <20k tris total (very conservative for modern hardware)

## Color Palette

### Classic NES TANKS1990 Colors (Arcade Retro)

Based on original 2D sprite palette:

```gdscript
# Tanks
const PLAYER_YELLOW = Color(0.95, 0.85, 0.2)  # Bright yellow
const PLAYER_GREEN = Color(0.3, 0.6, 0.2)      # Dark green (secondary)
const ENEMY_GRAY = Color(0.6, 0.6, 0.6)        # Light gray
const ENEMY_RED = Color(0.8, 0.2, 0.2)         # Red (Type 2)
const ENEMY_GREEN = Color(0.4, 0.7, 0.3)       # Green (Type 3)
const ENEMY_SILVER = Color(0.75, 0.75, 0.8)    # Silver (Type 4)

# Base/Eagle
const BASE_GRAY = Color(0.7, 0.7, 0.7)         # Light gray
const EAGLE_WHITE = Color(0.95, 0.95, 0.95)    # Bright white

# Bullets
const BULLET_WHITE = Color(1.0, 1.0, 1.0)      # Pure white

# Terrain
const BRICK_RED = Color(0.7, 0.3, 0.2)         # Dark red-brown
const STEEL_GRAY = Color(0.5, 0.5, 0.5)        # Medium gray
const WATER_BLUE = Color(0.2, 0.4, 0.7)        # Blue
const FOREST_GREEN = Color(0.2, 0.5, 0.2)      # Dark green

# Power-ups
const POWERUP_RED = Color(0.9, 0.2, 0.2)       # Bright red
const POWERUP_YELLOW = Color(0.95, 0.85, 0.2)  # Yellow
const POWERUP_SILVER = Color(0.8, 0.8, 0.85)   # Silver/white
```

## Dimensions and Scale

### Coordinate System

- **1 game unit = 1 meter in 3D**
- **2D grid cell = 1×1 unit**
- **26×26 grid = 26×26 world units**
- **Y=0 is ground plane**

### Entity Dimensions (3D world units)

| Entity      | Width | Length | Height | 2D Hitbox Reference |
| ----------- | ----- | ------ | ------ | ------------------- |
| Player Tank | 0.8   | 0.9    | 0.6    | 0.8×0.9 (2D)        |
| Enemy Tank  | 0.75  | 0.85   | 0.55   | 0.75×0.85 (2D)      |
| Base/Eagle  | 1.8   | 1.8    | 1.2    | 2×2 cells (2D)      |
| Bullet      | 0.15  | 0.15   | 0.15   | 0.1×0.1 (2D)        |
| Power-up    | 0.6   | 0.6    | 0.6    | 0.6×0.6 (2D)        |
| Brick Tile  | 1.0   | 1.0    | 0.5    | 1×1 cell (2D)       |
| Steel Tile  | 1.0   | 1.0    | 0.6    | 1×1 cell (2D)       |
| Water Tile  | 1.0   | 1.0    | 0.1    | 1×1 cell (2D)       |
| Forest Tile | 1.0   | 1.0    | 0.8    | 1×1 cell (2D)       |

### Anchor Points

- All entities positioned with origin at **ground center** (Y=0 at base)
- Turrets pivot at center of tank body
- Bullets spawn at turret tip position

## Mesh Specifications

### Player Tank (~500 tris)

**Components**:

1. **Body** (200 tris): Box chassis with angled front, detailed sides
2. **Turret** (150 tris): Cylindrical base + conical/box barrel
3. **Treads** (150 tris): Two side boxes with tread pattern detail

**Geometry**:

```
Body: Box(0.8, 0.4, 0.9) with angled front face
Turret Base: Cylinder(0.4 radius, 0.2 height, 16 sides) = 32 tris
Turret Barrel: Box(0.15, 0.15, 0.5) extending forward
Treads: 2× Box(0.1, 0.35, 0.85) on sides
```

**Colors**: PLAYER_YELLOW (main), PLAYER_GREEN (treads/details)

### Enemy Tanks (~300 tris each)

**Type 1 - Basic** (Gray):

- Simpler body (150 tris), smaller turret (100 tris), minimal treads (50 tris)
- Box body + cylindrical turret + simple side treads

**Type 2 - Light** (Red):

- Smaller, sleeker (same tri budget, more angular)
- Wedge-shaped body for speed aesthetic

**Type 3 - Heavy** (Green):

- Bulkier, wider body
- Larger turret, more prominent treads

**Type 4 - Fast** (Silver):

- Streamlined, low profile
- Minimal turret, thin treads

### Base/Eagle (~300 tris)

**Structure**:

- 2×2 units footprint (same as 2D: 2 cells)
- Iconic eagle/fortress shape
- Box base (50 tris) + tower structure (150 tris) + eagle emblem (100 tris)

**Geometry**:

```
Foundation: Box(1.8, 0.3, 1.8) at Y=0
Walls: 4× Box(0.2, 0.8, 1.8) forming square perimeter
Eagle: Stylized bird shape using triangulated polygons
```

**Colors**: BASE_GRAY (structure), EAGLE_WHITE (emblem)

### Bullet (~50 tris)

**Options**:

1. **Sphere** (preferred): UV Sphere with 16 sides, 8 rings = ~32 tris
2. **Cylinder**: 24-sided cylinder = ~48 tris

**Dimensions**: 0.15 unit diameter
**Color**: BULLET_WHITE

### Power-Ups (~100 tris each)

All power-ups use simple iconic shapes:

1. **Star** (extra life): 5-pointed star extrusion = ~80 tris
2. **Helmet** (shield): Dome + visor = ~100 tris
3. **Clock** (freeze): Circle + clock hands = ~60 tris
4. **Shovel** (base protect): Stylized shovel = ~80 tris
5. **Grenade** (bomb all): Sphere + fuse = ~70 tris
6. **Tank** (extra life): Miniature tank = ~100 tris

**Behavior**: All rotate slowly on Y-axis, slight bob animation

### Terrain Tiles

**Brick** (~12 tris):

- Simple cube: 6 faces × 2 tris = 12 tris
- Dimensions: 1×0.5×1 (width, height, depth)
- Color: BRICK_RED
- Destructible (remove on hit)

**Steel** (~12 tris):

- Cube: 12 tris
- Dimensions: 1×0.6×1 (slightly taller than brick)
- Color: STEEL_GRAY
- Indestructible (metallic appearance)

**Water** (~12 tris):

- Flat quad: 2 tris × 4 layers (animated) = ~12 tris
- Dimensions: 1×0.1×1 (thin surface)
- Color: WATER_BLUE (semi-transparent if needed later)
- Animated: UV scroll or vertex shader wave

**Forest** (~100 tris):

- 4-6 simple tree shapes (cones + cylinders)
- Each tree: ~20 tris × 5 trees = ~100 tris
- Dimensions: 1×0.8×1 (cell footprint, trees extend up)
- Color: FOREST_GREEN
- Passable (visual only, no collision)

## Material Configuration

### Unlit Shader (All Entities)

**File**: `resources/shaders/unlit_solid_color.gdshader`

```gdshader
shader_type spatial;
render_mode unshaded, cull_back;

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    ALBEDO = albedo_color.rgb;
    ALPHA = albedo_color.a;
}
```

**Usage**: Assign to StandardMaterial3D with `shading_mode = UNSHADED` or use custom ShaderMaterial

### Per-Entity Materials

Each mesh generator should create and assign materials:

```gdscript
var material = StandardMaterial3D.new()
material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
material.albedo_color = COLOR_CONSTANT
mesh.surface_set_material(0, material)
```

## Procedural Mesh Generation

### ArrayMesh Structure

All generators use Godot's ArrayMesh with SurfaceTool:

```gdscript
var surface_tool = SurfaceTool.new()
surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
# Add vertices, normals, UVs
surface_tool.add_vertex(Vector3(...))
# Generate indices automatically
surface_tool.index()
surface_tool.generate_normals()
var mesh = surface_tool.commit()
```

### Mesh Generator Files

Location: `resources/meshes3d/`

1. **tank_mesh_generator.gd**
   - `generate_player_tank() -> ArrayMesh`
   - `generate_enemy_tank(type: int) -> ArrayMesh` (types 1-4)
2. **base_mesh_generator.gd**
   - `generate_base_mesh() -> ArrayMesh`
3. **bullet_mesh_generator.gd**
   - `generate_bullet_mesh() -> ArrayMesh`
4. **terrain_mesh_generator.gd**

   - `generate_brick_tile() -> ArrayMesh`
   - `generate_steel_tile() -> ArrayMesh`
   - `generate_water_tile() -> ArrayMesh`
   - `generate_forest_tile() -> ArrayMesh`

5. **powerup_mesh_generator.gd** (optional for Phase 3, can defer)
   - `generate_powerup_mesh(type: int) -> ArrayMesh`

## Validation and Testing

### Test Scene

**File**: `scenes3d/test_3d_assets.tscn`

**Contents**:

- Camera3D (orthogonal, positioned to view all assets)
- Grid layout showing:
  - Player tank (center)
  - 4 enemy tank variants (surrounding)
  - Base/eagle (corner)
  - Bullet samples
  - Terrain tile samples (brick, steel, water, forest)
  - Power-ups (if implemented)
- Labels (Label3D) identifying each asset
- Lighting from Phase 2 environment

### Unit Tests

**File**: `tests/unit/test_mesh_generators.gd`

**Test Coverage**:

- Each generator returns valid ArrayMesh
- Vertex count within budget (calculate from tris: vertices ≈ tris × 3 / share_ratio)
- Mesh has proper surface count (>0)
- AABB (bounding box) is reasonable for game scale
- Material assigned correctly

### Triangle Count Verification

Script to measure actual triangle counts:

```gdscript
func count_triangles(mesh: ArrayMesh) -> int:
    var total = 0
    for i in mesh.get_surface_count():
        var arrays = mesh.surface_get_arrays(i)
        var indices = arrays[Mesh.ARRAY_INDEX]
        if indices:
            total += indices.size() / 3
        else:
            var vertices = arrays[Mesh.ARRAY_VERTEX]
            total += vertices.size() / 3
    return total
```

## Implementation Order

### Phase 3.1 - Core Meshes (Current)

1. ✅ Specification document (this file)
2. ⬜ Create directory structure
3. ⬜ Implement mesh generators:
   - tank_mesh_generator.gd (player + enemies)
   - base_mesh_generator.gd
   - bullet_mesh_generator.gd
   - terrain_mesh_generator.gd
4. ⬜ Create unlit shader
5. ⬜ Build test scene
6. ⬜ Write unit tests
7. ⬜ Verify triangle counts
8. ⬜ Run tests + compilation check

### Phase 3.2 - Polish (Future)

- Power-up mesh generators
- Animation blueprints (rotation, bobbing)
- VFX meshes (explosions, impacts)
- Particle systems for effects

## Performance Notes

### Optimization Strategies

- **Mesh Instancing**: Use MultiMeshInstance3D for terrain tiles (reuse same mesh)
- **LOD**: Not needed at this poly count and camera distance
- **Culling**: Frustum culling automatic; consider manual culling for off-screen entities
- **Batching**: Group static terrain into single mesh for draw call reduction

### Profiling Targets

- Frame time: <16ms (60 FPS)
- Draw calls: <50
- Triangle count: <20k simultaneous
- Memory: <10MB for all meshes

## References

- Knowledge Base: [2d-to-3d-godot-migration.md](../../ai-experts/docs/knowledge_base/2d-to-3d-godot-migration.md)
- Phase 2: [PHASE2_3D_CAMERA_COMPLETE.md](../PHASE2_3D_CAMERA_COMPLETE.md)
- Godot ArrayMesh: https://docs.godotengine.org/en/stable/classes/class_arraymesh.html
- SurfaceTool: https://docs.godotengine.org/en/stable/classes/class_surfacetool.html
- Low-poly techniques: Prioritize silhouette clarity over detail density

## Approval and Sign-off

**Design approved**: December 20, 2025  
**Ready for implementation**: ✅ YES  
**Estimated implementation time**: 4-6 hours  
**Risk assessment**: LOW (procedural generation is reversible, no external dependencies)
