SHELL := /bin/bash
.PHONY: help test lint check docs install-dev package release print-release-zip

ifeq ($(OS),Windows_NT)
PYTHON ?= python
else
PYTHON ?= python3
endif

DOCS_PORT ?= 3000

VERSION ?=
ifneq ($(strip $(VERSION)),)
RELEASE_ZIP := dist/godot-steam-voice-$(VERSION).zip
else
RELEASE_ZIP := dist/godot-steam-voice.zip
endif

help:
	@echo "Godot Steam Voice"
	@echo ""
	@echo "  make test    Run GdUnit4 headless tests"
	@echo "  make lint    Run gdlint"
	@echo "  make check   lint + test"
	@echo "  make docs    Serve Docsify site locally (port $(DOCS_PORT))"
	@echo "  make install-dev  Install pinned GdUnit4 (dev/CI dependency)"
	@echo "  make release Build dist/godot-steam-voice/ and zip (see VERSION below)"
	@echo "  make package Alias for make release"
	@echo ""
	@echo "Release zip: default dist/godot-steam-voice.zip"
	@echo "             VERSION=1.0.0 -> dist/godot-steam-voice-1.0.0.zip"
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

release:
	$(PYTHON) tools/package_addon.py --zip $(RELEASE_ZIP)

package: release

print-release-zip:
	@echo $(RELEASE_ZIP)

docs:
	@echo "Docs: http://127.0.0.1:$(DOCS_PORT)/"
	@echo "Press Ctrl+C to stop."
	cd docs && $(PYTHON) -m http.server $(DOCS_PORT)
