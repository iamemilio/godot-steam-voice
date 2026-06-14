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

### 2. Scene layout

Add **one** `VoiceSession` with **one** `VoiceChannel` child. On each player scene, add `VoiceMember` pointing at a **Node3D head** that moves with the player.

Players do **not** go under `VoiceSession`.

```
Main
├── VoiceSession
│   └── VoiceChannel          preset = Proximity
└── Player                    (your existing player scene)
    ├── Head                  Node3D — voice position
    └── VoiceMember           head_path = ../Head (default)
```

Set the channel preset and walkie/wall options in the Inspector. `VoiceMember` discovers the session in the scene tree and registers the local player as **listener** and remote players as **speakers**.

### 3. Start voice

Call `start()` when your game already has connected peers and Steam IDs (after your lobby / multiplayer setup):

```gdscript
@onready var session: VoiceSession = $VoiceSession

func _when_voice_should_start() -> void:
    session.start()

func _exit_tree() -> void:
    if session.is_active:
        session.stop()
```

### One channel by default

Proximity, walkie PTT, and wall muffling are **local playback rules** on **one** P2P stream. Turn on walkie in the Proximity channel Inspector (`use_walkie`, `push_to_talk_action`, `effects_bus_name`) — do **not** add a second channel for walkie + proximity.

| Topic | Read more |
|-------|-----------|
| Install, presets, Inspector groups | [Getting started](getting-started.md) |
| VoiceMember, lifecycle, manual registration | [Integration](integration.md) |
| Common setups | [Recipes](recipes.md) |
| Demo scenes | [Demo](demo.md) |
| Classes and methods | [API reference](api.md) |

---

## Requirements

- Godot **4.6+**
- [GodotSteam](https://godotsteam.com/) **4.19+** with voice API
- Steam client when testing live voice locally
