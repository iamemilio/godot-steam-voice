# Godot Steam Voice

Voice chat for Godot 4 games that already use [GodotSteam](https://godotsteam.com/) multiplayer.

---

## What this library does

Steam voice chat wired into your Godot scene tree. Register player head nodes when they spawn and call `begin_session()` when the match starts — the addon runs capture, P2P send/receive, and playback for you.

- **Proximity chat** — volume by distance; optional muffling through walls
- **Open mic or push-to-talk** — per channel
- **Multiple comms at once** — e.g. world voice and squad radio on separate channels (P2P ports assigned automatically)
- **Audio bus routing** — e.g. walkie-talkie EQ on a dedicated bus
- **Composable** — one simple channel is enough to start; stack modifiers when you need more

---

## How to use it

Add a **`VoiceSession`** node to your scene. Give it **`VoiceChannel`** children — one per comms mode (proximity, radio, etc.). Stack **`VoiceModifier`** resources on each channel for rules like spatial falloff, push-to-talk, or audio bus routing.

When the match starts, call `begin_session()`. When players spawn, register a head `Node3D` on each channel — `register_listener` for the local player, `register_speaker` for remotes. That is most of the integration.

```
VoiceSession
├── VoiceChannel ("Proximity")  → SpatialAttenuationModifier, …
└── VoiceChannel ("Radio")        → VoiceInputModifier, RosterModifier, …
```

```gdscript
session.begin_session()
proximity.register_listener(local_player.get_node("Head"))
proximity.register_speaker(steam_id, remote_player.get_node("Head"))
```

| Topic | Read more |
|-------|-----------|
| Install and first channel | [Getting started](getting-started.md) |
| Session lifecycle and Steam IDs | [Integration](integration.md) |
| Each bundled modifier | [Modifiers](modifiers.md) |
| Working example scene | [Demo walkthrough](demo.md) |
| Classes and methods | [API reference](api.md) |

---

## Requirements

- Godot **4.6+**
- [GodotSteam](https://godotsteam.com/) **4.19+** with voice API — required for live voice, not for automated tests
- Steam client running when testing live voice locally
