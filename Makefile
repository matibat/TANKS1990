SHELL := /bin/bash
SHELLFLAGS := -o pipefail -c

GODOT ?= godot
GUT_SCRIPT := addons/gut/gut_cmdln.gd
GUT_FLAGS ?= -gexit
GUT_PRE_HOOK ?= res://tests/hooks/pre_run_hook.gd
FATAL_GUT_PATTERN := \[ERROR\]:  Something went wrong and the run was aborted.

define RUN_GUT
	@echo "$(1)"
	@log_file=$$(mktemp); \
	fatal="$(FATAL_GUT_PATTERN)"; \
	parse_pat="SCRIPT ERROR.*Parse Error"; \
	compile_pat="SCRIPT ERROR.*Compile Error"; \
	load_pat="ERROR: Failed to load script"; \
	$(GODOT) --headless -s $(GUT_SCRIPT) -gdir=$(2) $(GUT_FLAGS) -gpre_run_script=$(GUT_PRE_HOOK) > $$log_file 2>&1 & \
	pid=$$!; \
	while kill -0 $$pid 2>/dev/null; do \
		if grep -q "$$fatal" $$log_file 2>/dev/null; then \
			echo "Detected fatal GUT error, stopping."; \
			kill $$pid 2>/dev/null || true; \
			break; \
		fi; \
		if grep -q "$$parse_pat" $$log_file 2>/dev/null || grep -q "$$compile_pat" $$log_file 2>/dev/null || grep -q "$$load_pat" $$log_file 2>/dev/null; then \
			echo "Detected compile/parse error, stopping."; \
			kill $$pid 2>/dev/null || true; \
			break; \
		fi; \
		sleep 0.2; \
	done; \
	wait $$pid; status=$$?; \
	if [ "$(3)" = "1" ] && (grep -q "$$parse_pat" $$log_file || grep -q "$$compile_pat" $$log_file || grep -q "$$load_pat" $$log_file); then \
		echo ""; \
		echo "=============================================="; \
		echo "Compile errors detected. Fix errors before running tests."; \
		echo "=============================================="; \
		cat $$log_file; \
		rm -f $$log_file; \
		exit 1; \
	fi; \
	cat $$log_file; \
	rm -f $$log_file; \
	exit $$status
endef

.PHONY: test test-unit test-integration test-performance check-compile

check-compile:
	$(call RUN_GUT,Checking for compile errors...,res://tests,1)

test:
	$(call RUN_GUT,Running full test suite...,res://tests,0)

test-unit:
	$(call RUN_GUT,Running unit tests...,res://tests/unit,0)

test-integration:
	$(call RUN_GUT,Running integration tests...,res://tests/integration,0)

test-performance:
	$(call RUN_GUT,Running performance tests...,res://tests/performance,0)

test-file:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make test-file FILE=res://tests/unit/test_example.gd"; \
		exit 1; \
	fi
	$(call RUN_GUT,Running specific test...,$(FILE),0)

# Development helpers
.PHONY: help clean demo3d edit validate

help:
	@echo "TANKS1990 - Makefile Commands"
	@echo "=============================="
	@echo ""
	@echo "Testing:"
	@echo "  make check-compile      - Check for GDScript compile errors (fast)"
	@echo "  make test               - Run all tests (unit + integration + performance)"
	@echo "  make test-unit          - Run only unit tests"
	@echo "  make test-integration   - Run integration tests"
	@echo "  make test-performance   - Run performance benchmarks"
	@echo "  make test-file FILE=... - Run specific test file"
	@echo ""
	@echo "3D Demo:"
	@echo "  make demo3d             - Open 3D demo scene in Godot editor"
	@echo "  make edit               - Open project in Godot editor"
	@echo ""
	@echo "Quality:"
	@echo "  make validate           - Run compile check + all tests"
	@echo "  make clean              - Clean temporary files"
	@echo ""
	@echo "Examples:"
	@echo "  make test-file FILE=res://tests/unit/test_tank3d.gd"
	@echo "  make demo3d             # See the 3D game in action!"

demo3d:
	@echo "Opening 3D demo scene..."
	@$(GODOT) scenes3d/demo3d.tscn

edit:
	@echo "Opening project in Godot editor..."
	@$(GODOT) -e project.godot

validate: check-compile test
	@echo ""
	@echo "✅ Validation complete!"

clean:
	@echo "Cleaning temporary files..."
	@rm -rf .godot/imported/.import/
	@rm -f .godot/uid_cache.bin~
	@find . -name "*.log" -type f -delete
	@echo "✅ Clean complete"