# Godot Steam Voice

Voice chat for Godot 4 + [GodotSteam](https://godotsteam.com/) — proximity, walkie-talkie effects, and wall muffling on **one voice stream** with client-owned playback rules.

**[Documentation](https://iamemilio.github.io/godot-steam-voice/)** · [Demo](demo/demo.tscn) · [Contributing](CONTRIBUTING.md)

## Requirements

- Godot 4.6+
- [GodotSteam](https://godotsteam.com/) 4.19+ (live voice)
- Steam client (local live testing)

## Quick start

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

One channel, one send, one decompress per packet — proximity and walkie are local playback rules, not separate network paths.

Read the **[docs](https://iamemilio.github.io/godot-steam-voice/)** for presets, recipes, and Advanced custom rules.

## License

MIT — see [LICENSE.txt](LICENSE.txt).
