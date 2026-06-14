SHELL := /bin/bash
.PHONY: help test lint check docs install-dev package

ifeq ($(OS),Windows_NT)
PYTHON ?= python
else
PYTHON ?= python3
endif

DOCS_PORT ?= 3000

help:
	@echo "Godot Steam Voice"
	@echo ""
	@echo "  make test    Run GdUnit4 headless tests"
	@echo "  make lint    Run gdlint"
	@echo "  make check   lint + test"
	@echo "  make docs    Serve Docsify site locally (port $(DOCS_PORT))"
	@echo "  make install-dev  Install pinned GdUnit4 (dev/CI dependency)"
	@echo "  make package Build dist/godot-steam-voice/ (addon files only)"
	@echo ""
	@echo "Override Godot: GODOT_PATH=/path/to/godot make test"
	@echo "Override port:  DOCS_PORT=8080 make docs"

test:
	$(PYTHON) tools/run_tests.py --tests-only

lint:
	$(PYTHON) tools/run_tests.py --lint-only

check:
	$(PYTHON) tools/run_tests.py

install-dev:
	$(PYTHON) tools/install_gdunit4.py

package:
	$(PYTHON) tools/package_addon.py --zip dist/godot-steam-voice.zip

docs:
	@echo "Docs: http://127.0.0.1:$(DOCS_PORT)/"
	@echo "Press Ctrl+C to stop."
	cd docs && $(PYTHON) -m http.server $(DOCS_PORT)
