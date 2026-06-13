# Steam Proximity Voice

Composable GodotSteam voice addon for Godot 4.x. Add `VoiceSession` nodes, create `VoiceChannel` children, stack `VoiceModifier` resources, and register listener/speaker `Node3D` refs once. Steam P2P ports are assigned automatically.

This folder is a **standalone Godot project** — you can copy it to its own repo, run tests, and contribute without the Friend Slop game. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Requirements

- Godot 4.6+
- [GodotSteam](https://godotsteam.com/) 4.19+ with voice API (`getVoice`, `decompressVoice`, `sendP2PPacket`, `readP2PPacket`)
- Steam client running for live voice

## Quick start

```
VoiceSession
├── VoiceChannel  (channel_name="Proximity")
│     modifiers = [SpatialAttenuationModifier, RoomOcclusionModifier]
└── VoiceChannel  (channel_name="Radio")
      modifiers = [VoiceInputModifier PTT, RosterModifier, RadioFilterModifier]
```

```gdscript
@onready var session := $VoiceSession
@onready var proximity := session.get_channel("Proximity")

func _on_match_started() -> void:
    session.begin_session()
    proximity.register_listener(local_player.get_node("Head"))

func _on_peer_spawned(steam_id: int, player: Node3D) -> void:
    proximity.register_speaker(steam_id, player.get_node("Head"))
```

## Open mic vs push-to-talk

- **No `VoiceInputModifier`** → open mic (default)
- **`VoiceInputModifier` with `OPEN_MIC`** → explicit open mic (settings toggle)
- **`VoiceInputModifier` with `PUSH_TO_TALK`** → send only while `input_action` is held

## Tests

From this directory (no Friend Slop, no Steam client):

```bash
make check
# or
python tools/run_tests.py
```

When embedded in Friend Slop, the game CI also runs these via `addons/steam_proximity_voice/tools/run_tests.py`.

## Demo

Open `demo/demo.tscn` in this project (or `addons/steam_proximity_voice/demo/demo.tscn` from Friend Slop) with two Steam clients and `steam_appid.txt`.

## License

MIT — see `LICENSE.txt`.
