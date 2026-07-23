# Godot Steam Voice

Voice chat for Godot 4 + [GodotSteam](https://godotsteam.com/) — proximity, walkie-talkie effects, and wall muffling on **one voice stream** with client-owned playback rules.

**[Documentation](https://iamemilio.github.io/godot-steam-voice/)** · [Demo](demo/demo.tscn) · [VoiceRuntime demo](demo/demo_runtime.tscn) · [Contributing](CONTRIBUTING.md)

## Requirements

- Godot 4.6+
- [GodotSteam](https://godotsteam.com/) 4.19+ (live voice)
- Steam client (local live testing)

## Quick start (VoiceRuntime)

Configure voice in the Inspector, then start/stop from code:

```
Main
├── LobbyRuntime     VoiceRuntime (EPHEMERAL_CLUSTER)
├── GameRuntime      VoiceRuntime (MEMBERS)
└── Player
    ├── Head
    └── VoiceMember
```

```gdscript
lobby_runtime.set_peers(steam_ids)
lobby_runtime.start()
# ...
lobby_runtime.stop()
game_runtime.set_peers(steam_ids)
game_runtime.start()
```

Sibling runtimes share one `VoiceSession`. Low-level `VoiceSession` + `VoiceChannel` remain available for manual setups.

Install: copy `addons/godot-steam-voice/` from a [release](https://github.com/iamemilio/godot-steam-voice/releases) or run `make release`.

Read the **[docs](https://iamemilio.github.io/godot-steam-voice/)** for presets, recipes, and Advanced custom rules.

## License

MIT — see [LICENSE.txt](LICENSE.txt).
