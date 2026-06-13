# Contributing to Steam Proximity Voice

This addon is developed as a **standalone Godot project** inside the Friend Slop monorepo. You can copy `addons/steam_proximity_voice/` to its own repository and work on it without the game.

## Prerequisites

- Godot **4.6+**
- Python **3.10+** (for the test runner)
- [gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit) (`pip install gdtoolkit`) for lint
- [GodotSteam](https://godotsteam.com/) — required for live voice and the demo; **not** required for unit tests

## Setup (standalone checkout)

1. Clone or copy this folder to a new repo root.
2. Install GodotSteam under `addons/godotsteam/` (see GodotSteam docs).
3. Optional: add `steam_appid.txt` (e.g. `480` for Spacewar) for manual voice testing.

## Running tests

From this directory:

```bash
make check          # gdlint + headless Godot tests
make test           # tests only
make lint           # gdlint only
```

Or directly:

```bash
python tools/run_tests.py
```

Set `GODOT_PATH` if Godot is not on your PATH:

```bash
GODOT_PATH=/path/to/godot make test
```

Tests run in **offline mode** (`STEAM_PROXIMITY_VOICE_TEST=1`). No Steam client is needed for CI-style unit tests.

The test runner runs `godot --import` on first use so global script classes (`VoiceModifier`, etc.) resolve correctly in this standalone project.

## Project layout

| Path | Purpose |
|------|---------|
| `voice_session.gd`, `voice_channel.gd` | Core session and channel nodes |
| `modifiers/` | Composable `VoiceModifier` resources |
| `demo/` | Example scene with proximity + radio channels |
| `tests/` | Unit and integration tests |
| `tools/run_tests.py` | Python entry point (lint + Godot headless) |
| `project.godot` | Minimal Godot project for standalone dev |

## Adding tests

1. Add a new `tests/test_*.gd` file extending `RefCounted` with a `run() -> int` method (return failure count).
2. Import and invoke it from `tests/run_tests.gd`.
3. Run `make test` before opening a PR.

Integration tests that need the scene tree should accept a `SceneTree` argument (see `test_voice_integration.gd`).

## Code style

- Match existing naming and modifier patterns.
- Keep Friend Slop–specific code out of this addon; game integration belongs in the host project (e.g. `scripts/voice/friend_slop_voice_adapter.gd` in Friend Slop).
- Run `make lint` — gdlint must pass on the addon root.

## Manual voice testing

See [MANUAL_TEST.md](MANUAL_TEST.md) for two-client Steam smoke tests (cannot run in headless CI).
