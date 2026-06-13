# Demo walkthrough

The demo is a standalone example: **proximity** (open mic + spatial) and **radio** (PTT + roster + bus routing) running in parallel.

## Files

| File | Role |
|------|------|
| [`demo/demo.tscn`](https://github.com/iamemilio/godot-steam-voice/blob/main/demo/demo.tscn) | Scene tree, channel modifiers |
| [`demo/demo.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/demo/demo.gd) | Session lifecycle, registration glue |

## Scene tree

```
SteamVoiceDemo (demo.gd)
└── VoiceSession
    ├── Proximity   → SpatialAttenuationModifier (5 m / 30 m)
    └── Radio       → VoiceInputModifier (PTT), RosterModifier, RadioFilterModifier
```

Proximity has **no** `VoiceInputModifier` — open mic by default.

Radio uses input action **`radio_push`** (define in Input Map).

## Running locally

1. Install GodotSteam under `addons/godotsteam/`.
2. Add `steam_appid.txt` at the project root.
3. Run the project with the Steam client open.
4. Host/join via your game's Steam lobby, then spawn demo players with a `Head` child node.

## What demo.gd does

### Session start

[`_ready`](https://github.com/iamemilio/godot-steam-voice/blob/main/demo/demo.gd#L10-L17) configures the radio roster, collects session Steam IDs, and defers `begin_session()`.

[`_begin_when_ready`](https://github.com/iamemilio/godot-steam-voice/blob/main/demo/demo.gd#L30-L34) starts the voice session when a multiplayer peer exists.

### Roster for radio

[`_configure_radio_roster`](https://github.com/iamemilio/godot-steam-voice/blob/main/demo/demo.gd#L20-L27) sets `RosterModifier.membership_fn` to return all connected Steam IDs from the multiplayer API.

### Player registration

[`register_demo_player`](https://github.com/iamemilio/godot-steam-voice/blob/main/demo/demo.gd#L51-L67):

- Local authority → `register_listener` on both channels
- Remote players → `register_speaker(steam_id, head)` on both channels

[`_register_local_listener`](https://github.com/iamemilio/godot-steam-voice/blob/main/demo/demo.gd#L36-L48) finds the local player in group `demo_player` and registers their `Head` node.

### Cleanup

[`_exit_tree`](https://github.com/iamemilio/godot-steam-voice/blob/main/demo/demo.gd#L70-L72) calls `session.end_session()`.

## Smoke tests

[`tests/test_demo_scene.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/tests/test_demo_scene.gd) verifies the scene loads and expected modifiers are wired on each channel.

## Not in the demo

These are documented and tested but not wired in `demo.tscn`:

- `RoomOcclusionModifier` + `RoomGraph`
- `GainModifier`
- `AudioBusFilterModifier` (non-radio preset)

See [Modifiers](modifiers.md) and the linked test files for those.
