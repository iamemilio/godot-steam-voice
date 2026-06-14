# Getting started

**Prerequisite:** your game already connects peers and resolves Steam IDs. This addon does not cover lobbies, spawning, or multiplayer setup.

## Install

1. Copy `godot-steam-voice/` into `your_game/addons/godot-steam-voice/` (from a [release zip](https://github.com/iamemilio/godot-steam-voice/releases) or `make release` in this repo).
2. Install [GodotSteam](https://godotsteam.com/) in your project if you have not already.
3. Enable GodotSteam and confirm voice capture works in your environment.

## Scene setup

One session node, one channel child, one `VoiceMember` per player:

```
Main
├── VoiceSession
│   └── VoiceChannel          preset = Proximity
└── Player
    ├── Head                  Node3D
    └── VoiceMember           head_path = ../Head (default)
```

- **`Head`** — any `Node3D` at the position you want voice to come from (usually the camera or head bone target).
- **`VoiceMember`** — default `head_path` is `../Head` (sibling under the same player root). Change it if your scene hierarchy differs.
- **`VoiceChannel`** — must be a **direct child** of `VoiceSession`.

## Minimal script

```gdscript
@onready var session: VoiceSession = $VoiceSession

func _when_peers_ready() -> void:
    session.start()

func _exit_tree() -> void:
    if session.is_active:
        session.stop()
```

Call `start()` after your multiplayer session is up. `VoiceMember` nodes register automatically via deferred `_enter_tree` — no manual `register_listener` / `register_speaker` calls needed for the usual single-channel setup.

Optional: set `VoiceSession.auto_start = true` if `get_session_peers()` is already populated when the session node loads.

## Presets

| Preset | What you get |
|--------|----------------|
| **Global** | Everyone hears everyone, open mic |
| **Proximity** | Distance-based volume; optional walkie and wall muffling in Inspector |
| **Custom** | Stack `VoiceRule` resources yourself ([Advanced](advanced.md)) |

## Proximity Inspector groups

On `VoiceChannel` when preset = **Proximity**:

- **Proximity voice** — `near_full_volume_m`, `far_silent_m`
- **Wall muffling** — `use_wall_muffling` (assign `MufflingMap` on `VoiceSession`)
- **Walkie** — `use_walkie`, `push_to_talk_action`, `effects_bus_name`, optional `walkie_use_channel_members` / `walkie_membership`

With **Proximity + walkie**, open-mic proximity transmit stays on; holding the walkie PTT action sets `VoicePacket.FLAG_WALKIE_ACTIVE` on that frame so clients apply the effects bus locally.

Define input actions in Project → Input Map (e.g. `radio_push`).

## Audio bus for walkie

Create a bus named `VoiceRadio` in Project → Audio and add EQ or filters. When `use_walkie` is enabled, walkie transmissions route playback through `effects_bus_name` on receiving clients.

See [Recipes](recipes.md) and the [demo](demo.md).
