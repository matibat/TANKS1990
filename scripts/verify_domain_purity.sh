#!/bin/bash
# Domain Layer Purity Verification Script
# Ensures domain layer has zero Godot coupling

set -o pipefail

# Get the project root (parent of scripts/)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "=== Domain Layer Purity Verification ==="
echo ""
echo "Checking: src/domain/"
echo ""

# Counters
total_files=0
total_violations=0
violation_files=0

# Forbidden patterns with descriptions
# Format: "pattern|description"
declare -a pattern_checks=(
    'extends Node[^a-zA-Z]|Godot Node inheritance'
    'extends Node2D|Godot Node2D inheritance'
    'extends Node3D|Godot Node3D inheritance'
    'extends Control|Godot Control inheritance'
    'extends Resource[^a-zA-Z]|Godot Resource inheritance (use RefCounted)'
    '@export|Godot @export annotation'
    '@onready|Godot @onready annotation'
    '\$[A-Za-z_]|Godot node path reference'
    'load\("res://.*\.tscn"|Scene file loading'
    'preload\("res://.*\.tscn"|Scene file preloading'
    'load\("res://.*\.tres"|Resource file loading'
    'preload\("res://.*\.tres"|Resource file preloading'
    'get_node|Godot get_node() call'
    'get_tree|Godot get_tree() call'
    'Engine\.|Godot Engine singleton access'
    'OS\.|Godot OS singleton access'
)

# Allowed patterns (to verify)
allowed_extends=("extends RefCounted" "extends Object")

# Function to check a single file
check_file() {
    local file="$1"
    local file_violations=0
    local file_has_violation=0
    
    # Check for allowed extends first
    local has_allowed_extends=0
    for allowed in "${allowed_extends[@]}"; do
        if grep -q "^class_name .* *$" "$file" && ! grep -q "^extends " "$file"; then
            # Class with no explicit extends (implicitly extends RefCounted in Godot 4)
            has_allowed_extends=1
            break
        elif grep -q "$allowed" "$file"; then
            has_allowed_extends=1
            break
        fi
    done
    
    # Check each forbidden pattern
    for pattern_entry in "${pattern_checks[@]}"; do
        local pattern="${pattern_entry%%|*}"
        local description="${pattern_entry#*|}"
        local matches
        
        # Use grep with line numbers
        if matches=$(grep -n -E "$pattern" "$file" 2>/dev/null); then
            if [ $file_has_violation -eq 0 ]; then
                echo "❌ $file"
                file_has_violation=1
                ((violation_files++))
            fi
            
            # Print each match
            while IFS= read -r match; do
                local line_num=$(echo "$match" | cut -d: -f1)
                local line_content=$(echo "$match" | cut -d: -f2-)
                echo "   Line $line_num: $description"
                echo "   └─> $(echo "$line_content" | sed 's/^[[:space:]]*//')"
                ((file_violations++))
                ((total_violations++))
            done <<< "$matches"
        fi
    done
    
    # If no violations, mark as clean
    if [ $file_has_violation -eq 0 ]; then
        echo "✅ $file"
    fi
    
    echo ""
}

# Find all .gd files in src/domain/
echo "Scanning domain files..."
echo ""

while IFS= read -r -d '' file; do
    ((total_files++))
    check_file "$file"
done < <(find src/domain -name "*.gd" -type f -print0 | sort -z)

# Summary
echo "========================================="
echo "Summary:"
echo "  Total files checked: $total_files"
echo "  Files with violations: $violation_files"
echo "  Total violations: $total_violations"
echo ""

if [ $total_violations -eq 0 ]; then
    echo "✅ Domain layer is pure! No Godot coupling detected."
    exit 0
else
    echo "❌ Domain layer has Godot coupling violations!"
    echo ""
    echo "Required fixes:"
    echo "  • Replace 'extends Node*' with 'extends RefCounted'"
    echo "  • Remove @export, @onready, and node path references"
    echo "  • Remove scene/resource file loading"
    echo "  • Use pure GDScript classes only"
    exit 1
fi
