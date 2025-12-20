#!/bin/bash
## Quick 3D Gameplay Validation Script
## Tests that the 3D game scene loads and runs correctly

set -e

echo "=== 3D Gameplay Validation ==="
echo ""

echo "1. Testing scene load..."
godot --headless --quit scenes3d/game_3d_ddd.tscn 2>&1 | grep -E "(GameRoot3D ready|Tank spawned|Terrain rendered)" && echo "✅ Scene loads successfully" || echo "❌ Scene failed to load"

echo ""
echo "2. Checking required files..."
for file in "scenes3d/game_3d_ddd.tscn" "scenes3d/game_root_3d.gd" "scenes3d/terrain_tile_3d.gd" "src/autoload/debug_logger.gd"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
    fi
done

echo ""
echo "3. Checking autoload registration..."
grep -q "DebugLogger" project.godot && echo "✅ DebugLogger registered" || echo "❌ DebugLogger not registered"

echo ""
echo "4. Testing Makefile target..."
grep -q "game_3d_ddd.tscn" Makefile && echo "✅ Makefile updated" || echo "❌ Makefile not updated"

echo ""
echo "=== Validation Complete ==="
echo ""
echo "To run the game:"
echo "  make demo3d"
echo "  # or"
echo "  godot scenes3d/game_3d_ddd.tscn"
