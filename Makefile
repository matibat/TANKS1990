SHELL := /bin/bash
SHELLFLAGS := -o pipefail -c

GODOT ?= godot
GUT_SCRIPT := addons/gut/gut_cmdln.gd
GUT_FLAGS ?= -gexit
GUT_PRE_HOOK ?= res://tests/hooks/pre_run_hook.gd

# Verbosity control
VERBOSE ?= 0
QUIET ?= 0
LOG_OUTPUT ?= 0
MAKE_VERBOSE := $(if $(filter environment,$(origin VERBOSE)),0,$(VERBOSE))
MAKE_LOG_OUTPUT := $(if $(filter environment,$(origin LOG_OUTPUT)),0,$(LOG_OUTPUT))
LOG_DIR := .godot/logs

.DEFAULT_GOAL := help

# Macro for running Godot checks with output control
# Args: $(1)=command, $(2)=logfile, $(3)=error_pattern, $(4)=exclude_pattern, $(5)=success_msg
define run_godot_check
	@mkdir -p $(LOG_DIR)
	@if [ "$(MAKE_VERBOSE)" = "1" ]; then \
		$(1) 2>&1 | tee $(LOG_DIR)/$(2); \
		if grep -E "$(3)" $(LOG_DIR)/$(2) $(if $(4),| grep -v "$(4)",) > /dev/null; then \
			echo ""; \
			echo "❌ $(5) failed. See output above."; \
			exit 1; \
		fi; \
	else \
		$(1) > $(LOG_DIR)/$(2) 2>&1; \
		if grep -E "$(3)" $(LOG_DIR)/$(2) $(if $(4),| grep -v "$(4)",) > /dev/null; then \
			echo ""; \
			echo "❌ $(5) failed. Full output:"; \
			if [ "$(QUIET)" = "1" ]; then \
				grep -E "ERROR|SCRIPT ERROR|Parse Error|Compile Error" $(LOG_DIR)/$(2) || cat $(LOG_DIR)/$(2); \
			else \
				cat $(LOG_DIR)/$(2); \
			fi; \
			exit 1; \
		fi; \
		if [ "$(MAKE_VERBOSE)" != "1" ]; then \
			echo "✅ $(5)"; \
		else \
			echo "✅ $(5)"; \
		fi; \
	fi
endef

# Early-fail: Check assets and compilation before running tests
.PHONY: precheck check-import check-compile

precheck: check-import check-compile
	@echo "✅ All pre-checks passed"

check-import:
	@echo "Importing assets..."
	$(call run_godot_check,$(GODOT) --headless --import --quit,check-import.log,SCRIPT ERROR|Parse Error|Compile Error,RID allocations|resources still in use|ObjectDB instances leaked,Assets imported successfully)

check-compile:
	@echo "Checking GDScript compilation..."
	$(call run_godot_check,$(GODOT) --headless --script res://tests/hooks/compile_check.gd --quit,check-compile.log,SCRIPT ERROR|Parse Error|Compile Error,,All scripts compiled successfully)

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
	@mkdir -p $(LOG_DIR)
	@suite=$${SUITE:-all}; \
	pattern=$${PATTERN:-}; \
	flag_verbose=$${VERBOSE:-0}; \
	flag_quiet=$${QUIET:-0}; \
	flag_logs=$${LOG_OUTPUT:-0}; \
	echo "Flags: VERBOSE=$$flag_verbose QUIET=$$flag_quiet LOG_OUTPUT=$$flag_logs"; \
	logdir=$(LOG_DIR); \
	logfile=$$(mktemp "$${logdir}/gut-test.XXXXXX.log"); \
	trap 'rm -f "$$logfile"' EXIT; \
	if [ "$$suite" = "all" ]; then \
		test_dir="res://tests"; \
	else \
		test_dir="res://tests/$$suite"; \
	fi; \
	run_gut() { \
		cmd=$$1; \
		if [ "$(MAKE_VERBOSE)" = "1" ]; then \
			eval "$$cmd" 2>&1 | tee "$$logfile"; \
		else \
			eval "$$cmd" > "$$logfile" 2>&1; \
		fi; \
	}; \
	status=0; \
	if [ -n "$$pattern" ]; then \
		echo "Running tests matching '$$pattern' in $$test_dir..."; \
		run_gut '$(GODOT) --headless -s $(GUT_SCRIPT) -gdir=$$test_dir -gselect=$$pattern $(GUT_FLAGS) -gpre_run_script=$(GUT_PRE_HOOK)' || status=$$?; \
	else \
		echo "Running all tests in $$test_dir..."; \
		run_gut '$(GODOT) --headless -s $(GUT_SCRIPT) -gdir=$$test_dir $(GUT_FLAGS) -gpre_run_script=$(GUT_PRE_HOOK)' || status=$$?; \
	fi; \
	total=$$(grep "^Tests" "$$logfile" | awk '{print $$NF}' | head -n1); \
	total=$${total:-0}; \
	passing=$$(grep "^Passing Tests" "$$logfile" | awk '{print $$NF}' | head -n1); \
	passing=$${passing:-0}; \
	failing=$$(grep "^Failing Tests" "$$logfile" | awk '{print $$NF}' | head -n1); \
	failing=$${failing:-0}; \
	if [ "$$failing" -gt 0 ]; then \
		status=1; \
	fi; \
	if [ $$status -ne 0 ]; then \
		echo ""; \
		if [ "$(MAKE_VERBOSE)" = "1" ]; then \
			echo "❌ Tests failed (see output above)."; \
		elif [ "$(MAKE_LOG_OUTPUT)" = "1" ]; then \
			echo "❌ Tests failed. Full output:"; \
			cat "$$logfile"; \
		elif [ "$(QUIET)" = "1" ]; then \
			echo "❌ Tests failed. Errors only:"; \
			grep -E "SCRIPT ERROR|ERROR:|Parse Error|Compile Error|\[Failed\]|---- .* failing" "$$logfile" || cat "$$logfile"; \
		else \
			echo "❌ Tests failed. Summary:"; \
			awk 'BEGIN {show=0} {if ($$0 ~ /Run Summary/) {if (prev_nonempty != "") print prev_nonempty; print; show=1; next} if (show) print; if ($$0 != "") prev_nonempty=$$0}' "$$logfile"; \
		fi; \
		echo ""; \
		printf "Total registered tests: %s\n" "$$total"; \
		printf "Passing tests: %s\n" "$$passing"; \
		printf "Failing tests: %s\n" "$$failing"; \
		exit $$status; \
	fi; \
	echo ""; \
	if [ "$(MAKE_VERBOSE)" = "1" ]; then \
		printf "✅ Tests passed: %s/%s\n" "$$passing" "$$total"; \
	elif [ "$(MAKE_LOG_OUTPUT)" = "1" ]; then \
		echo "✅ Tests passed: $$passing/$$total. Full output:"; \
		cat "$$logfile"; \
	else \
		if [ "$(QUIET)" != "1" ]; then \
			grep -E "WARNING:|Deprecated" "$$logfile" || true; \
		fi; \
		if [ -n "$$pattern" ] && [ "$$total" -eq 0 ]; then \
			echo ""; \
			echo "⚠️ Pattern '$$pattern' matched no tests."; \
			echo "   PATTERN filters case-sensitive substrings of GUT test names (e.g., PATTERN=test_game_loop)."; \
		fi; \
		printf "Total registered tests: %s\n" "$$total"; \
		printf "Passing tests: %s\n" "$$passing"; \
		printf "✅ Tests passed: %s/%s\n" "$$passing" "$$total"; \
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
.PHONY: help clean demo3d edit validate check-script validate-script check-errors verify-domain

# Script-level development commands
# Usage:
#   make check-script FILE=src/domain/entities/tank_entity.gd
#   make validate-script FILE=tests/domain/test_game_loop.gd
#   make check-errors FILE=scenes3d/tank_3d.gd

check-script:
	@if [ -z "$(FILE)" ]; then \
		echo "❌ Error: FILE parameter required"; \
		echo "Usage: make check-script FILE=<path_to_file.gd>"; \
		echo "Example: make check-script FILE=src/domain/entities/tank_entity.gd"; \
		exit 1; \
	fi
	@if [ ! -f "$(FILE)" ]; then \
		echo "❌ Error: File '$(FILE)' not found"; \
		exit 1; \
	fi
	@echo "Checking syntax of $(FILE)..."
	@$(GODOT) --headless --check-only --script $(FILE) 2>&1 | tee /tmp/check-script.log
	@if grep -q "ERROR\|SCRIPT ERROR\|Parse Error" /tmp/check-script.log; then \
		echo ""; \
		echo "❌ Syntax errors detected in $(FILE)"; \
		rm -f /tmp/check-script.log; \
		exit 1; \
	fi
	@rm -f /tmp/check-script.log
	@echo "✅ $(FILE) syntax is valid"

validate-script:
	@if [ -z "$(FILE)" ]; then \
		echo "❌ Error: FILE parameter required"; \
		echo "Usage: make validate-script FILE=<path_to_file.gd>"; \
		echo "Example: make validate-script FILE=tests/domain/test_game_loop.gd"; \
		exit 1; \
	fi
	@if [ ! -f "$(FILE)" ]; then \
		echo "❌ Error: File '$(FILE)' not found"; \
		exit 1; \
	fi
	@echo "Validating script $(FILE)..."
	@$(GODOT) --headless --script $(FILE) 2>&1 | tee /tmp/validate-script.log
	@if grep -q "SCRIPT ERROR\|Parse Error\|Compile Error" /tmp/validate-script.log; then \
		echo ""; \
		echo "❌ Validation errors detected in $(FILE)"; \
		cat /tmp/validate-script.log; \
		rm -f /tmp/validate-script.log; \
		exit 1; \
	fi
	@rm -f /tmp/validate-script.log
	@echo "✅ $(FILE) validated successfully"

check-errors:
	@if [ -z "$(FILE)" ]; then \
		echo "❌ Error: FILE parameter required"; \
		echo "Usage: make check-errors FILE=<path_to_file.gd>"; \
		echo "Example: make check-errors FILE=scenes3d/tank_3d.gd"; \
		exit 1; \
	fi
	@if [ ! -f "$(FILE)" ]; then \
		echo "❌ Error: File '$(FILE)' not found"; \
		exit 1; \
	fi
	@echo "Checking for detailed errors in $(FILE)..."
	@$(GODOT) --headless --check-only --script $(FILE) 2>&1 | tee /tmp/check-errors.log
	@echo ""
	@echo "Full error output for $(FILE):"
	@cat /tmp/check-errors.log
	@rm -f /tmp/check-errors.log

verify-domain:
	@echo "Verifying domain layer purity..."
	@bash scripts/verify_domain_purity.sh

help:
	@echo "TANKS1990 - Makefile Commands"
	@echo "=============================="
	@echo ""
	@echo "Pre-checks (run automatically before tests):"
	@echo "  make precheck           - Run all pre-checks (imports + compilation)"
	@echo "  make check-import       - Import all assets"
	@echo "  make check-compile      - Check GDScript compilation"
	@echo ""
	@echo "Output control flags (for check-import, check-compile, and test):"
	@echo "  VERBOSE=1               - Show full real-time output (all tests, logs, everything)"
	@echo "  LOG_OUTPUT=1            - Show full buffered output on completion (all logs)"
	@echo "  QUIET=1                 - Show minimal output with errors only"
	@echo "  Default                 - Show summary with test structure and warnings"
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
	@echo "Script-level development:"
	@echo "  make check-script FILE=<path>    - Check syntax of a single GDScript file"
	@echo "  make validate-script FILE=<path> - Run validation on a single script"
	@echo "  make check-errors FILE=<path>    - Show detailed errors for a file"
	@echo ""
	@echo "Quality:"
	@echo "  make validate           - Run all pre-checks + all tests"
	@echo "  make verify-domain      - Verify domain layer has zero Godot coupling"
	@echo "  make clean              - Clean temporary files"
	@echo ""
	@echo "Examples:"
	@echo "  make test                              # Run everything"
	@echo "  make test SUITE=domain                 # Just domain tests"
	@echo "  make test PATTERN=test_game_loop       # Tests matching pattern"
	@echo "  make test SUITE=domain PATTERN=tank    # Domain tests with 'tank' in name"
	@echo "  make check-script FILE=src/domain/entities/tank_entity.gd  # Check single file"
	@echo "  make demo3d                            # See the 3D game!"

demo3d:
	@echo "Opening 3D demo scene..."
	@$(GODOT) scenes3d/game_3d_ddd.tscn

edit:
	@echo "Opening project in Godot editor..."
	@$(GODOT) -e project.godot

validate: precheck test
	@echo ""
	@echo "✅ Validation complete!"

audio-import:
	@echo "Generating and importing audio assets..."
	@python3 generate_audio.py
	@echo "✅ Audio assets imported!"

clean:
	@echo "Cleaning temporary files..."
	@rm -rf .godot/imported/.import/
	@rm -rf $(LOG_DIR)
	@rm -f .godot/uid_cache.bin~
	@rm -f /tmp/check-*.log
	@find . -name "*.log" -type f -delete
	@echo "✅ Clean complete"