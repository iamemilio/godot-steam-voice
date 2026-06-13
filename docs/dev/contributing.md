# Contributing

This repo is a **standalone Godot project**. Copy it into `addons/steam_proximity_voice/` in a host game, or develop it directly here.

## Prerequisites

- Godot **4.6+**
- Python **3.10+** (test runner)
- [gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit) — `pip install -r requirements.txt`
- [GdUnit4](https://github.com/godot-gdunit-labs/gdUnit4) — vendored under `addons/gdUnit4/` (dev only; do not ship to games)
- [GodotSteam](https://godotsteam.com/) — optional; live demo only

## Setup

1. Clone the repository.
2. Optional: install GodotSteam under `addons/godotsteam/` and add `steam_appid.txt` for live voice.

Enable the GdUnit4 plugin in Project → Project Settings → Plugins to run tests from the Godot editor.

## Project layout

| Path | Purpose |
|------|---------|
| `voice_session.gd`, `voice_channel.gd` | Core session and channel nodes |
| `modifiers/` | Composable `VoiceModifier` resources |
| `demo/` | Example scene |
| `tests/` | GdUnit4 suites |
| `tests/helpers/` | Test doubles |
| `addons/gdUnit4/` | GdUnit4 framework (dev only) |
| `tools/run_tests.py` | Python entry point |
| `docs/` | Docsify documentation (GitHub Pages) |

When copying into a game, ship core scripts + `demo/` only unless you want tests in the host project.

## Documentation site

User-facing docs live in `docs/` (Docsify). Preview locally:

```bash
make docs
```

Published via GitHub Pages: branch `main`, folder `/docs`.

## Code style

- Match existing naming and modifier patterns.
- Keep game-specific integration in the host project, not in this addon.
- Run `make lint` before opening a PR.

See [Testing & CI](dev/testing.md) for how to run tests and what CI expects.
