# Getting started

Prerequisite: your game already has connected peers and Steam IDs.

## Scene setup

```
VoiceSession
└── VoiceChannel          preset = Proximity
Player
├── Head
└── VoiceMember           head_path → Head
```

## Minimal script

```gdscript
@onready var session := $VoiceSession

func _when_peers_ready() -> void:
    session.start()
```

Each player needs a **Node3D at the head** that moves with them. `VoiceMember` wires it to voice automatically.

## Presets

| Preset | What you get |
|--------|----------------|
| **Global** | Everyone hears everyone, open mic |
| **Proximity** | Louder when close; optional walkie and wall muffling in Inspector |
| **Custom** | Stack `VoiceRule` resources (Advanced) |

## Proximity Inspector groups

- **Proximity voice** — `near_full_volume_m`, `far_silent_m`
- **Wall muffling** — `use_wall_muffling` (assign `MufflingMap` on `VoiceSession`)
- **Walkie** — `use_walkie`, `push_to_talk_action`, `effects_bus_name`

Define input actions in Project → Input Map (e.g. `radio_push`).

## Audio bus for walkie

Create a bus named `VoiceRadio` in Project → Audio and add EQ or filters there. The channel routes walkie playback to that bus when `use_walkie` is enabled.

See [Recipes](recipes.md) and the [demo](demo.md).
