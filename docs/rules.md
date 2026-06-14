# Rules

Advanced composable building blocks. Beginners use **presets** on `VoiceChannel` instead of picking rule classes.

| Rule | Contract |
|------|----------|
| `ProximityVolume` | Playback volume depends on distance between players |
| `WallMuffling` | Playback quieter through walls/doors |
| `MicMode` | Controls when the mic transmits; sets walkie flag on envelope |
| `ChannelMembers` | Restricts who can talk and listen |
| `VolumeBoost` | Adds a fixed dB offset |
| `VoiceEffectsBus` | Plays voice on a Godot audio bus (e.g. walkie EQ) |

Source: [`rules/`](../rules/)

Toggle at runtime: `channel.set_rule_enabled("ProximityVolume", false)`.

See [Advanced](advanced.md) for CUSTOM preset composition.
