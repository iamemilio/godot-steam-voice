# Testing & CI

## Running tests locally

First-time setup:

```bash
pip install -r requirements.txt
make install-dev    # optional — make test installs GdUnit4 if missing
```

```bash
make check          # gdlint + GdUnit4 headless tests
make test           # tests only
make lint           # gdlint only
```

Or:

```bash
python tools/run_tests.py
```

Set `GODOT_PATH` if Godot is not on your PATH:

```bash
GODOT_PATH=/path/to/godot make test
```

Tests run in offline mode (`STEAM_PROXIMITY_VOICE_TEST=1`). **No Steam client required.**

The runner invokes `godot --import` on first use so global script classes resolve correctly.

GdUnit4 writes HTML and JUnit reports under `reports/` (gitignored). Open `reports/report_*/index.html` for a local breakdown.

## Test suites

| File | Coverage |
|------|----------|
| `test_multiplayer_voice.gd` | Single-lane transport, send/receive pipeline |
| `test_proximity_chat.gd` | Proximity preset, wall muffling |
| `test_spatial_audio.gd` | ProximityVolume math and playback wiring |
| `test_voice_playback.gd` | VoiceSpeakerHandle PCM buffer and AudioStreamGenerator flush |
| `test_audio_fixtures.gd` | Golden WAV fixture load, hash, fake transport replay, receive pipeline |
| `test_steam_integration.gd` | Transport, PCM, peer adapter |
| `test_room_graph.gd` | `MufflingMap` wall layout |
| `test_voice_patterns.gd` | Presets, transmit flags, VoiceMember, single-lane guard |
| `test_demo_scene.gd` | Demo scene smoke tests |

## Audio test fixtures

Record WAV files into `tests/fixtures/audio/` with:

```bash
make audio-recording
```

This opens a standalone recorder window (not the editor, not headless). The tool lives under `tools/` and is **not** included in `make release` packages.

See [tests/fixtures/audio/README.md](../../tests/fixtures/audio/README.md).

## Adding tests

1. Add or extend a file under `tests/` that **extends `GdUnitTestSuite`**.
2. Name methods `test_*` and use GdUnit4 assertions.
3. Use `auto_free()` for nodes created in tests.
4. Run `make test` before opening a PR.

## CI on pull requests

GitHub Actions runs:

| Job | Command |
|-----|---------|
| **lint** | `gdlint` on project root (excludes `addons/`) |
| **test** | Installs GdUnit4 + `python tools/run_tests.py --tests-only` |
| **CodeQL** | Static analysis for Python (`tools/run_tests.py`); GDScript is not a CodeQL language |

Failed tests appear as named annotations on the PR. Download the **gdunit4-reports** artifact for the HTML report.

## GodotSteam editor note

Transport offline behavior is tested via `FakeSteamVoiceTransport`, not the live Steam singleton — tests should pass on plain Godot and GodotSteam editors alike.
