# Godot Steam Voice

Voice chat for Godot 4 games that already use [GodotSteam](https://godotsteam.com/) voice.

---

## What this library does

One voice stream per session: capture, P2P send/receive, and **client-owned playback** (proximity gain, walkie effects, wall muffling).

- **Proximity** — volume by distance on one channel
- **Walkie** — optional PTT + audio bus on the **same** channel (not a second network path)
- **Wall muffling** — optional `MufflingMap`
- **Custom rules** — stack `VoiceRule` resources when presets are not enough

This addon handles **voice only**. Lobbies, player spawn, and netcode stay in your game.

---

## How to use it

### 1. Install the addon

Copy the packaged addon into your Godot project:

```
your_game/addons/godot-steam-voice/
```

Get it from [GitHub Releases](https://github.com/iamemilio/godot-steam-voice/releases) (`godot-steam-voice-<version>.zip`) or run `make release` in this repo.

You also need [GodotSteam](https://godotsteam.com/) with the voice API enabled in your project.

### 2. Scene layout (VoiceRuntime)

Add **`VoiceRuntime`** nodes and tune `VoiceContextConfig` in the Inspector. Call `start()` / `stop()` from code. Sibling runtimes share one `VoiceSession`.

```
Main
├── LobbyRuntime              VoiceRuntime (EPHEMERAL_CLUSTER)
├── GameRuntime               VoiceRuntime (MEMBERS)
└── Player
    ├── Head                  Node3D — voice position
    └── VoiceMember           head_path = ../Head (default)
```

```gdscript
@onready var lobby_runtime: VoiceRuntime = $LobbyRuntime
@onready var game_runtime: VoiceRuntime = $GameRuntime

func enter_lobby(ids: Array[int]) -> void:
    game_runtime.stop()
    lobby_runtime.set_peers(ids)
    lobby_runtime.start()
```

Low-level `VoiceSession` + `VoiceChannel` remain available — see [Getting started](getting-started.md).

### 3. One channel by default

Proximity, walkie PTT, and wall muffling are **local playback rules** on **one** P2P stream. Turn on walkie in the Proximity channel Inspector (`use_walkie`, `push_to_talk_action`, `effects_bus_name`) — do **not** add a second channel for walkie + proximity.

| Topic | Read more |
|-------|-----------|
| Install, VoiceRuntime, presets | [Getting started](getting-started.md) |
| VoiceMember, lifecycle, manual registration | [Integration](integration.md) |
| Common setups | [Recipes](recipes.md) |
| Demo scenes | [Demo](demo.md) |
| Classes and methods | [API reference](api.md) |

---

## Requirements

- Godot **4.6+**
- [GodotSteam](https://godotsteam.com/) **4.19+** with voice API
- Steam client when testing live voice locally
