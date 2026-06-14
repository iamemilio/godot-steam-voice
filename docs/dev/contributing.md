# Contributing

This repo is a **standalone Godot project** for developing and testing the addon. Ship games using the packaged addon under `addons/godot-steam-voice/` (see [Packaging for distribution](#packaging-for-distribution)), not by copying this whole repo.

## Prerequisites

- Godot **4.6+**
- Python **3.10+** (test runner)
- [gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit) — `pip install -r requirements.txt`
- [GdUnit4](https://github.com/godot-gdunit-labs/gdUnit4) — installed on demand via `make install-dev` (pinned in `tools/gdunit4_version.txt`; not committed to git)
- [GodotSteam](https://godotsteam.com/) — optional; live demo only
- **git** — required to install GdUnit4

## Setup

1. Clone the repository.
2. `pip install -r requirements.txt`
3. `make install-dev` — clones pinned GdUnit4 into `addons/gdUnit4/` (gitignored; runtime + CLI only, no GdUnit4 test suite)
4. Optional: copy `tools/godot_path.local.example` → `tools/godot_path.local.txt` with your Godot executable path (gitignored).
5. Optional: install GodotSteam under `addons/godotsteam/` and add `steam_appid.txt` for live voice.

`make test` and CI install GdUnit4 automatically if missing.

Enable the GdUnit4 plugin in Project → Project Settings → Plugins to run tests from the Godot editor.

## Project layout

| Path | Purpose |
|------|---------|
| `voice_session.gd`, `voice_channel.gd`, `voice_member.gd` | Core nodes |
| `rules/` | Composable `VoiceRule` resources |
| `voice_packet.gd`, `muffling_map.gd` | Transport envelope and wall map |
| `demo/` | Example scene |
| `tests/` | GdUnit4 suites |
| `tests/helpers/` | Test doubles |
| `tools/gdunit4_version.txt` | Pinned GdUnit4 release |
| `tools/install_gdunit4.py` | Installs minimal GdUnit4 to `addons/gdUnit4/` |
| `tools/run_tests.py` | Python entry point |
| `docs/` | Docsify documentation (GitHub Pages) |

When copying into a game, ship core scripts + `demo/` only unless you want tests in the host project.

## Packaging for distribution

This repo is a **dev project** (tests, docs, CI, GdUnit4). Games should not copy the whole repo.

```bash
make release
```

Writes **`dist/godot-steam-voice/`** and a zip under **`dist/`**

Default zip: **`dist/godot-steam-voice.zip`**. For release-style naming (same as CI on tags):

```bash
make release VERSION=1.0.0
# -> dist/godot-steam-voice-1.0.0.zip
```

Output is addon scripts, `rules/`, `adapters/`, and `INSTALL.txt` only. No `tests/`, `tools/`, `docs/`, `demo/`, or `project.godot`.

Install in a game:

```
your_game/addons/godot-steam-voice/
```

Or run `python tools/package_addon.py --out /path/to/addons/godot-steam-voice` (used internally by `make release`).

**CI releases:** push a version tag (`v1.0.0`) or run the **Release** workflow manually. Both use `make release` (with `VERSION` from the tag when applicable). Artifacts are `godot-steam-voice-<version>.zip` (addon folder ready for `your_game/addons/godot-steam-voice/`).

## Documentation site

User-facing docs live in `docs/` (Docsify). Preview locally:

```bash
make docs
```

Published via GitHub Pages: branch `main`, folder `/docs`.

## Code style

- Match existing naming and rule patterns.
- Keep game-specific integration in the host project, not in this addon.
- Run `make lint` before opening a PR.

See [Testing & CI](dev/testing.md) for how to run tests and what CI expects.
