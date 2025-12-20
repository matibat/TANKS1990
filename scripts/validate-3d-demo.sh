#!/bin/bash
# Quick validation script for 3D demo fixes

echo "=== TANKS1990 3D Demo Validation ==="
echo ""

# Get the project root (parent of scripts/)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "Working directory: $PWD"
echo ""

# Test 1: Check critical files exist
echo "✓ Checking files..."
files=(
    "scenes3d/game_controller_3d.gd"
    "scenes3d/simple_ai_3d.gd"
    "src/managers/bullet_manager_3d.gd"
    "tests/integration/test_3d_gameplay.gd"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ❌ $file (MISSING)"
        exit 1
    fi
done

# Test 2: Check project.godot settings
echo ""
echo "✓ Checking project settings..."
if grep -q 'run/main_scene="res://scenes3d/demo3d.tscn"' project.godot; then
    echo "  ✓ Main scene set to demo3d.tscn"
else
    echo "  ❌ Main scene not set correctly"
    exit 1
fi

if grep -q 'window/size/viewport_width=832' project.godot; then
    echo "  ✓ Window width = 832"
else
    echo "  ❌ Window width not set"
    exit 1
fi

if grep -q 'window/size/mode=0' project.godot; then
    echo "  ✓ Window mode = windowed"
else
    echo "  ❌ Window mode not set"
    exit 1
fi

# Test 3: Syntax check with Godot (quick)
echo ""
echo "✓ Checking GDScript syntax..."
timeout 10 godot --headless --path . --quit 2>&1 | grep -q "ERROR" && {
    echo "  ❌ Syntax errors detected"
    exit 1
} || {
    echo "  ✓ No syntax errors"
}

# Test 4: Scene loading test
echo ""
echo "✓ Testing scene load..."
timeout 10 godot --headless --path . -s scenes3d/demo3d.tscn --quit 2>&1 > /tmp/godot_test.log
if grep -q "ERROR" /tmp/godot_test.log; then
    echo "  ❌ Scene load errors:"
    grep "ERROR" /tmp/godot_test.log | head -5
    exit 1
else
    echo "  ✓ Scene loads cleanly"
fi

echo ""
echo "==================================="
echo "✅ All validation checks passed!"
echo "==================================="
echo ""
echo "To play the game:"
echo "  make demo3d"
echo "  OR"
echo "  godot scenes3d/demo3d.tscn"
echo ""
echo "Controls:"
echo "  Arrow Keys - Move player"
echo "  Space - Shoot"
echo ""
