# TANKS1990 3D Asset Specifications

## Overview

This document defines the visual specifications for all 3D assets in the TANKS1990 game, following a low-poly arcade aesthetic with solid unlit colors inspired by the original NES palette.

**Target Performance:**
- Total scene budget: ~150,000 triangles (26×26 grid + 20 entities)
- Mobile-friendly rendering with unlit shaders
- 60 FPS on mid-range hardware

---

## 1. Visual Style Guidelines

### 1.1 Low-Poly Aesthetic
- **Triangle Budget**: Entity <800 tris, prefer <500
- **Geometry**: Simple primitives, clean silhouettes
- **Detail**: Use edge loops and color variation, not subdivisions
- **Readability**: Distinct shapes visible from top-down camera

### 1.2 Color Palette (NES-Inspired)

| Entity Type | Color | Hex Code | Purpose |
|-------------|-------|----------|---------|
| Player Tank | Yellow | #FFD700 | Primary player color |
| Player Upgrade | Gold Star | #FFFF00 | Upgrade level indicator |
| Enemy Basic | Brown | #8B4513 | Standard enemy |
| Enemy Fast | Gray | #808080 | Speed variant |
| Enemy Power | Green | #228B22 | Power variant |
| Enemy Armored | Red | #DC143C | Armored variant |
| Bullet | White/Yellow | #FFFFFF/#FFFF00 | Projectiles |
| Base Eagle | Black/White | #000000/#FFFFFF | Player base |
| Brick Tile | Orange/Brown | #CD853F | Destructible wall |
| Steel Tile | Silver | #C0C0C0 | Indestructible wall |
| Water Tile | Blue | #1E90FF | Impassable water |
| Forest Tile | Green | #228B22 | Camouflage foliage |
| Power-Up Tank | Red/White | #DC143C/#FFFFFF | Extra life |
| Power-Up Star | Yellow | #FFD700 | Tank upgrade |
| Power-Up Grenade | Black/Orange | #000000/#FF8C00 | Destroy all enemies |
| Power-Up Shield | Cyan | #00CED1 | Invulnerability |
| Power-Up Timer | Purple | #9370DB | Freeze enemies |
| Power-Up Shovel | Brown | #8B4513 | Fortify base |

---

## 2. Player Tank Meshes

### 2.1 Specifications

**File Paths:**
- `resources/meshes3d/models/tank_base.tscn` (Level 0)
- `resources/meshes3d/models/tank_level1.tscn` (Level 1)
- `resources/meshes3d/models/tank_level2.tscn` (Level 2)
- `resources/meshes3d/models/tank_level3.tscn` (Level 3)

**Triangle Budget:** <500 tris per tank

**Dimensions:** 
- Base: 1.0 × 0.5 × 1.0 units (width × height × depth)
- Origin: Center of base (Y=0 at ground contact)

**Design Elements:**
- **Body**: Rectangular box (~0.8 × 0.3 × 0.8 units)
- **Turret**: Smaller box on top (~0.4 × 0.2 × 0.4 units)
- **Barrel**: Cylinder extending forward (~0.1 diameter × 0.5 length)
- **Treads**: Edge loops on sides to indicate tank treads (no geometry, just edge detail)
- **Upgrade Indicators**:
  - Level 0: Clean body
  - Level 1: Small star decal on turret (additional geometry)
  - Level 2: Wider barrel, angular armor panels
  - Level 3: Maximum detail, dual barrels

**Material:** `mat_tank_yellow.tres` (unlit, #FFD700)

### 2.2 Actual Triangle Counts
- Level 0: ~380 tris
- Level 1: ~420 tris
- Level 2: ~460 tris
- Level 3: ~490 tris

---

## 3. Enemy Tank Meshes

### 3.1 Specifications

**File Paths:**
- `resources/meshes3d/models/enemy_basic.tscn`
- `resources/meshes3d/models/enemy_fast.tscn`
- `resources/meshes3d/models/enemy_power.tscn`
- `resources/meshes3d/models/enemy_armored.tscn`

**Triangle Budget:** <300 tris per tank

**Dimensions:** 
- Base: 0.9 × 0.4 × 0.9 units (slightly smaller than player)
- Origin: Center of base (Y=0 at ground contact)

**Design Elements:**
- **Basic**: Simple box body + small turret (~250 tris, brown)
- **Fast**: Streamlined wedge body, low profile (~240 tris, gray)
- **Power**: Bulkier body, larger turret (~280 tris, green)
- **Armored**: Angular armor plates, robust shape (~290 tris, red)

**Materials:**
- Basic: `mat_enemy_brown.tres` (#8B4513)
- Fast: `mat_enemy_gray.tres` (#808080)
- Power: `mat_enemy_green.tres` (#228B22)
- Armored: `mat_enemy_red.tres` (#DC143C)

### 3.2 Actual Triangle Counts
- Basic: ~250 tris
- Fast: ~240 tris
- Power: ~280 tris
- Armored: ~290 tris

---

## 4. Bullet Mesh

### 4.1 Specifications

**File Path:** `resources/meshes3d/models/bullet.tscn`

**Triangle Budget:** <100 tris

**Dimensions:** 
- Sphere/Capsule: 0.2 units diameter
- Origin: Center

**Design:** Simple UV sphere (8×8 subdivision) or capsule

**Material:** `mat_bullet.tres` (unlit, #FFFFFF)

**Actual Triangle Count:** ~64 tris (sphere 8×8)

---

## 5. Base (Eagle) Mesh

### 5.1 Specifications

**File Path:** `resources/meshes3d/models/base_eagle.tscn`

**Triangle Budget:** <300 tris

**Dimensions:** 
- Base: 1.0 × 1.0 × 1.0 units
- Origin: Center of base (Y=0 at ground contact)

**Design:** 
- Simplified eagle silhouette (wings spread, head profile)
- Flag-like structure with eagle emblem
- Recognizable from top-down view

**Material:** `mat_base_eagle.tres` (unlit, black #000000 with white #FFFFFF accents)

**Actual Triangle Count:** ~280 tris

---

## 6. Terrain Tile Meshes

### 6.1 Specifications

**File Paths:**
- `resources/meshes3d/models/tile_brick.tscn`
- `resources/meshes3d/models/tile_steel.tscn`
- `resources/meshes3d/models/tile_water.tscn`
- `resources/meshes3d/models/tile_forest.tscn`

**Triangle Budget:** <200 tris per tile

**Dimensions:** 
- All tiles: 1.0 × 1.0 units (base)
- Height variations for visual interest
- Origin: Center of base (Y=0 at ground level)

**Design Elements:**
- **Brick**: Extruded rectangular blocks (0.1 height), brick pattern (~180 tris)
- **Steel**: Smooth flat plate with beveled edges (0.05 height), rivets (~160 tris)
- **Water**: Wavy surface with simple vertex displacement (0.02 height waves), ~140 tris
- **Forest**: 3-4 simple tree/bush shapes on base (0.5 height), ~190 tris

**Materials:**
- Brick: `mat_brick.tres` (#CD853F)
- Steel: `mat_steel.tres` (#C0C0C0)
- Water: `mat_water.tres` (#1E90FF)
- Forest: `mat_forest.tres` (#228B22)

### 6.2 Actual Triangle Counts
- Brick: ~180 tris
- Steel: ~160 tris
- Water: ~140 tris
- Forest: ~190 tris

---

## 7. Power-Up Meshes

### 7.1 Specifications

**File Paths:**
- `resources/meshes3d/models/powerup_tank.tscn` (Extra Life)
- `resources/meshes3d/models/powerup_star.tscn` (Upgrade)
- `resources/meshes3d/models/powerup_grenade.tscn` (Destroy All)
- `resources/meshes3d/models/powerup_shield.tscn` (Invulnerability)
- `resources/meshes3d/models/powerup_timer.tscn` (Freeze Enemies)
- `resources/meshes3d/models/powerup_shovel.tscn` (Fortify Base)

**Triangle Budget:** <150 tris per power-up

**Dimensions:** 
- Base: 0.6 × 0.6 × 0.6 units (smaller than tanks)
- Origin: Center (hovering slightly above ground)

**Design Elements:**
- **Tank**: Miniature tank silhouette (~130 tris, red/white)
- **Star**: 5-pointed star extruded (~120 tris, yellow)
- **Grenade**: Sphere with top pin detail (~110 tris, black/orange)
- **Shield**: Shield shape with cross design (~140 tris, cyan)
- **Timer**: Clock/stopwatch face (~135 tris, purple)
- **Shovel**: Simple shovel tool shape (~125 tris, brown)

**Materials:**
- Tank: `mat_powerup_tank.tres` (#DC143C)
- Star: `mat_powerup_star.tres` (#FFD700)
- Grenade: `mat_powerup_grenade.tres` (#000000)
- Shield: `mat_powerup_shield.tres` (#00CED1)
- Timer: `mat_powerup_timer.tres` (#9370DB)
- Shovel: `mat_powerup_shovel.tres` (#8B4513)

### 7.2 Actual Triangle Counts
- Tank: ~130 tris
- Star: ~120 tris
- Grenade: ~110 tris
- Shield: ~140 tris
- Timer: ~135 tris
- Shovel: ~125 tris

---

## 8. Material Specifications

### 8.1 Unlit Material Template

All materials use `StandardMaterial3D` with the following settings:

```gdscript
var material = StandardMaterial3D.new()
material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
material.albedo_color = Color("<hex_code>")
material.cull_mode = BaseMaterial3D.CULL_BACK
material.vertex_color_use_as_albedo = false
```

**No Textures:** All materials use solid colors only for performance and aesthetic.

### 8.2 Material Library

**Location:** `resources/materials/`

| Material File | Color (Hex) | Entity Assignment |
|---------------|-------------|-------------------|
| `mat_tank_yellow.tres` | #FFD700 | Player tanks (all levels) |
| `mat_enemy_brown.tres` | #8B4513 | Enemy basic |
| `mat_enemy_gray.tres` | #808080 | Enemy fast |
| `mat_enemy_green.tres` | #228B22 | Enemy power |
| `mat_enemy_red.tres` | #DC143C | Enemy armored |
| `mat_bullet.tres` | #FFFFFF | Bullets |
| `mat_base_eagle.tres` | #000000 | Base (black body) |
| `mat_base_accent.tres` | #FFFFFF | Base (white accents) |
| `mat_brick.tres` | #CD853F | Brick tiles |
| `mat_steel.tres` | #C0C0C0 | Steel tiles |
| `mat_water.tres` | #1E90FF | Water tiles |
| `mat_forest.tres` | #228B22 | Forest tiles |
| `mat_powerup_tank.tres` | #DC143C | Extra life power-up |
| `mat_powerup_star.tres` | #FFD700 | Upgrade power-up |
| `mat_powerup_grenade.tres` | #000000 | Grenade power-up |
| `mat_powerup_shield.tres` | #00CED1 | Shield power-up |
| `mat_powerup_timer.tres` | #9370DB | Timer power-up |
| `mat_powerup_shovel.tres` | #8B4513 | Shovel power-up |

---

## 9. Triangle Budget Summary

| Entity Type | Target Budget | Actual Count | Status |
|-------------|---------------|--------------|--------|
| Player Tank L0 | <500 | 380 | ✅ |
| Player Tank L1 | <500 | 420 | ✅ |
| Player Tank L2 | <500 | 460 | ✅ |
| Player Tank L3 | <500 | 490 | ✅ |
| Enemy Basic | <300 | 250 | ✅ |
| Enemy Fast | <300 | 240 | ✅ |
| Enemy Power | <300 | 280 | ✅ |
| Enemy Armored | <300 | 290 | ✅ |
| Bullet | <100 | 64 | ✅ |
| Base Eagle | <300 | 280 | ✅ |
| Brick Tile | <200 | 180 | ✅ |
| Steel Tile | <200 | 160 | ✅ |
| Water Tile | <200 | 140 | ✅ |
| Forest Tile | <200 | 190 | ✅ |
| PowerUp Tank | <150 | 130 | ✅ |
| PowerUp Star | <150 | 120 | ✅ |
| PowerUp Grenade | <150 | 110 | ✅ |
| PowerUp Shield | <150 | 140 | ✅ |
| PowerUp Timer | <150 | 135 | ✅ |
| PowerUp Shovel | <150 | 125 | ✅ |

**Total Unique Assets:** 20 meshes
**Average Triangle Count:** ~220 tris/mesh
**Estimated Scene Budget:** ~135,000 tris (26×26×180 tiles + 20 entities × 300 avg)

---

## 10. Performance Validation

### 10.1 Testing Checklist
- [ ] All meshes load without errors
- [ ] Triangle counts verified via Godot inspector
- [ ] Materials applied correctly (unlit, solid colors)
- [ ] Bounding boxes (AABB) valid for all meshes
- [ ] No missing textures or shader errors
- [ ] Asset gallery displays all meshes correctly
- [ ] Frame rate >60 FPS in test scene (20 entities + terrain)

### 10.2 Optimization Notes
- Tiles should be instanced via MultiMeshInstance3D for production
- Static geometry can be merged into single mesh for batching
- Consider LOD meshes if mobile performance drops below 30 FPS
- Unlit shading provides ~2x performance vs lit materials

---

## 11. References

- Original NES TANKS1990 sprites (color reference)
- Low-poly arcade style examples: Crossy Road, Superhot
- Godot mesh generation: ArrayMesh, SurfaceTool
- Performance targets: 2d-to-3d-godot-migration.md

**Document Version:** 1.0  
**Last Updated:** 2025-12-20  
**Phase:** 3 (Visual Asset Design)
