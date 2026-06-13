# Godot Steam Voice

Voice chat for Godot 4 + [GodotSteam](https://godotsteam.com/) multiplayer — proximity chat, push-to-talk channels, spatial audio, and composable modifiers without hand-rolling capture, P2P routing, and per-player playback.

**[Documentation](https://iamemilio.github.io/godot-steam-voice/)** · [Demo](demo/demo.tscn) · [Contributing](CONTRIBUTING.md)

GodotSteam gives you the raw voice APIs; this addon turns them into scene-tree nodes you wire once per match: a `VoiceSession`, `VoiceChannel` children for each comms mode, optional `VoiceModifier` resources, and head-node registration when players spawn.

## Requirements

- Godot 4.6+
- [GodotSteam](https://godotsteam.com/) 4.19+ (live voice)
- Steam client (local live testing)

## Quick start

```
VoiceSession
└── VoiceChannel  (channel_name="Proximity")
      modifiers = [SpatialAttenuationModifier]
```

```gdscript
session.begin_session()
proximity.register_listener(local_player.get_node("Head"))
proximity.register_speaker(steam_id, player.get_node("Head"))
```

Read the **[docs](https://iamemilio.github.io/godot-steam-voice/)** for the full picture (why, how it fits your match flow, modifiers, demo).

## License

MIT — see [LICENSE.txt](LICENSE.txt).
