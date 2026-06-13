# Getting started

New here? Start with the [home page](README.md) for **why** this library exists and how `VoiceSession` / `VoiceChannel` / modifiers fit together. This page is the practical **how-to**.

## Install in your game

1. Copy the addon scripts into your project (e.g. `addons/steam_proximity_voice/`).
2. Copy core `.gd` files, `modifiers/`, and optionally `adapters/`.
3. Do **not** copy `tests/` or `addons/gdUnit4/` into a shipping game unless you want them for development.
4. Install [GodotSteam](https://godotsteam.com/) in your project.
5. Add `steam_appid.txt` at the project root for local Steam testing.

See the [demo scene](demo.md) for a full working example.

## Scene setup

```
VoiceSession
├── VoiceChannel  (channel_name="Proximity")
│     modifiers = [SpatialAttenuationModifier]
└── VoiceChannel  (channel_name="Radio")
      modifiers = [VoiceInputModifier, RosterModifier, RadioFilterModifier]
```

Assign modifiers in the Inspector on each `VoiceChannel`'s `modifiers` array, or embed them in a `.tscn` like the demo.

## Minimal integration

```gdscript
@onready var session := $VoiceSession
@onready var proximity := session.get_channel("Proximity")

func _on_match_started() -> void:
    session.set_session_peers(collect_steam_ids_somehow())
    session.begin_session()
    proximity.register_listener(local_player.get_node("Head"))

func _on_peer_spawned(steam_id: int, player: Node3D) -> void:
    proximity.register_speaker(steam_id, player.get_node("Head"))
```

Each player needs a **`Node3D` at the head** (or camera) that moves with them. Spatial modifiers use those positions for distance and occlusion.

## Open mic vs push-to-talk

| Setup | Behavior |
|-------|----------|
| No `VoiceInputModifier` | Open mic (default) |
| `VoiceInputModifier` + `OPEN_MIC` | Explicit open mic (e.g. settings toggle) |
| `VoiceInputModifier` + `PUSH_TO_TALK` | Send only while `input_action` is held |

Define input actions in Project → Input Map (e.g. `radio_push` for the demo radio channel).

## Complexity guide

| Goal | Effort |
|------|--------|
| Global open mic | Low — one channel, no modifiers |
| Proximity / spatial | Low — add `SpatialAttenuationModifier`, same registration code |
| Room muffling through walls | Medium — `RoomOcclusionModifier` + `RoomGraph` on `VoiceSession` |
| Radio channel | Medium — PTT + roster + audio bus in Project → Audio |

Details: [Modifiers](modifiers.md) · [Integration](integration.md)
