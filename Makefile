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
	$(call RUN_GUT,Running specific test...,$(FILE),0)

# Please make me meaningful!