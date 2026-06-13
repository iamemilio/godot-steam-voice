SHELL := /bin/bash
.PHONY: help test lint check

ifeq ($(OS),Windows_NT)
PYTHON ?= python
else
PYTHON ?= python3
endif

help:
	@echo "steam_proximity_voice (standalone addon)"
	@echo ""
	@echo "  make test    Run headless Godot unit tests"
	@echo "  make lint    Run gdlint on this addon"
	@echo "  make check   lint + test"
	@echo ""
	@echo "Override Godot: GODOT_PATH=/path/to/godot make test"

test:
	$(PYTHON) tools/run_tests.py --tests-only

lint:
	$(PYTHON) tools/run_tests.py --lint-only

check:
	$(PYTHON) tools/run_tests.py
