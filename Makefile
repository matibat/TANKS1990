SHELL := /bin/bash
SHELLFLAGS := -o pipefail -c

GODOT ?= godot
GUT_SCRIPT := addons/gut/gut_cmdln.gd
GUT_FLAGS ?= -gexit
GUT_PRE_HOOK ?= res://tests/hooks/pre_run_hook.gd

# Early-fail: Check assets and compilation before running tests
.PHONY: precheck check-only check-import check-compile

precheck: check-only check-import check-compile
	@echo "✅ All pre-checks passed"

check-only:
	@echo "Checking assets and project validity..."
	@$(GODOT) --headless --check-only --quit 2>&1 | tee /tmp/check-only.log
	@if grep -q "ERROR\|SCRIPT ERROR" /tmp/check-only.log; then \
		echo ""; \
		echo "❌ Asset or project errors detected. Fix before proceeding."; \
		rm -f /tmp/check-only.log; \
		exit 1; \
	fi
	@rm -f /tmp/check-only.log
	@echo "✅ Assets and project valid"

check-import:
	@echo "Importing assets..."
	@$(GODOT) --headless --import --quit 2>&1 | tee /tmp/check-import.log
	@if grep -q "ERROR\|SCRIPT ERROR" /tmp/check-import.log; then \
		echo ""; \
		echo "❌ Import errors detected. Fix before proceeding."; \
		rm -f /tmp/check-import.log; \
		exit 1; \
	fi
	@rm -f /tmp/check-import.log
	@echo "✅ Assets imported successfully"

check-compile:
	@echo "Checking GDScript compilation..."
	@$(GODOT) --headless --script res://tests/hooks/compile_check.gd --quit 2>&1 | tee /tmp/check-compile.log
	@if grep -q "SCRIPT ERROR\|Parse Error\|Compile Error" /tmp/check-compile.log; then \
		echo ""; \
		echo "❌ Compilation errors detected. Fix before running tests."; \
		cat /tmp/check-compile.log; \
		rm -f /tmp/check-compile.log; \
		exit 1; \
	fi
	@rm -f /tmp/check-compile.log
	@echo "✅ All scripts compiled successfully"

# Test runner: Unified command for all test scenarios
.PHONY: test

# Test runner: Unified command for all test scenarios
.PHONY: test

# Usage:
#   make test                          # Run all tests
#   make test SUITE=domain            # Run domain tests only
#   make test SUITE=integration       # Run integration tests only
#   make test SUITE=unit              # Run unit tests only
#   make test PATTERN=test_tank       # Run tests matching pattern
#   make test SUITE=domain PATTERN=test_tank_entity  # Combine filters
test: precheck
	@suite=$${SUITE:-all}; \
	pattern=$${PATTERN:-}; \
	if [ "$$suite" = "all" ]; then \
		test_dir="res://tests"; \
	else \
		test_dir="res://tests/$$suite"; \
	fi; \
	if [ -n "$$pattern" ]; then \
		echo "Running tests matching '$$pattern' in $$test_dir..."; \
		$(GODOT) --headless -s $(GUT_SCRIPT) -gdir=$$test_dir -gselect=$$pattern $(GUT_FLAGS) -gpre_run_script=$(GUT_PRE_HOOK); \
	else \
		echo "Running all tests in $$test_dir..."; \
		$(GODOT) --headless -s $(GUT_SCRIPT) -gdir=$$test_dir $(GUT_FLAGS) -gpre_run_script=$(GUT_PRE_HOOK); \
	fi

# Legacy aliases for backward compatibility (all use unified test command)
.PHONY: test-unit test-integration test-performance test-domain

test-unit:
	@$(MAKE) test SUITE=unit

test-integration:
	@$(MAKE) test SUITE=integration

test-performance:
	@$(MAKE) test SUITE=performance

test-domain:
	@$(MAKE) test SUITE=domain


# Development helpers
.PHONY: help clean demo3d edit validate

help:
	@echo "TANKS1990 - Makefile Commands"
	@echo "=============================="
	@echo ""
	@echo "Pre-checks (run automatically before tests):"
	@echo "  make precheck           - Run all pre-checks (assets + imports + compilation)"
	@echo "  make check-only         - Check assets and project validity"
	@echo "  make check-import       - Import all assets"
	@echo "  make check-compile      - Check GDScript compilation"
	@echo ""
	@echo "Testing (unified interface):"
	@echo "  make test                      - Run all tests"
	@echo "  make test SUITE=domain         - Run domain tests only"
	@echo "  make test SUITE=integration    - Run integration tests only"
	@echo "  make test SUITE=unit           - Run unit tests only"
	@echo "  make test PATTERN=test_tank    - Run tests matching pattern"
	@echo "  make test SUITE=domain PATTERN=test_tank_entity  - Combine filters"
	@echo ""
	@echo "Testing (legacy aliases):"
	@echo "  make test-domain        - Run domain tests"
	@echo "  make test-integration   - Run integration tests"
	@echo "  make test-unit          - Run unit tests"
	@echo "  make test-performance   - Run performance tests"
	@echo ""
	@echo "3D Demo:"
	@echo "  make demo3d             - Open 3D demo scene in Godot editor"
	@echo "  make edit               - Open project in Godot editor"
	@echo ""
	@echo "Quality:"
	@echo "  make validate           - Run all pre-checks + all tests"
	@echo "  make clean              - Clean temporary files"
	@echo ""
	@echo "Examples:"
	@echo "  make test                              # Run everything"
	@echo "  make test SUITE=domain                 # Just domain tests"
	@echo "  make test PATTERN=test_game_loop       # Tests matching pattern"
	@echo "  make test SUITE=domain PATTERN=tank    # Domain tests with 'tank' in name"
	@echo "  make demo3d                            # See the 3D game!"

demo3d:
	@echo "Opening 3D demo scene..."
	@$(GODOT) scenes3d/demo3d.tscn

edit:
	@echo "Opening project in Godot editor..."
	@$(GODOT) -e project.godot

validate: precheck test
	@echo ""
	@echo "✅ Validation complete!"

clean:
	@echo "Cleaning temporary files..."
	@rm -rf .godot/imported/.import/
	@rm -f .godot/uid_cache.bin~
	@rm -f /tmp/check-*.log
	@find . -name "*.log" -type f -delete
	@echo "✅ Clean complete"