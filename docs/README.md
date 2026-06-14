# Godot Steam Voice

Voice chat for Godot 4 games that already use [GodotSteam](https://godotsteam.com/) voice.

---

## What this library does

One voice stream per session: capture, P2P send/receive, and **client-owned playback** (proximity gain, walkie effects, wall muffling).

- **Proximity** — volume by distance on one channel
- **Walkie** — optional PTT + audio bus on the **same** channel (not a second network path)
- **Wall muffling** — optional `MufflingMap`
- **Custom rules** — stack `VoiceRule` resources when presets are not enough

---

## How to use it

```
VoiceSession
└── VoiceChannel          preset = Proximity
Player
├── Head
└── VoiceMember
```

```gdscript
session.start()
```

| Topic | Read more |
|-------|-----------|
| Install and presets | [Getting started](getting-started.md) |
| VoiceMember and lifecycle | [Integration](integration.md) |
| Common setups | [Recipes](recipes.md) |
| Demo scene | [Demo](demo.md) |
| Classes and methods | [API reference](api.md) |

---

## Requirements

- Godot **4.6+**
- [GodotSteam](https://godotsteam.com/) **4.19+** with voice API
- Steam client when testing live voice locally
