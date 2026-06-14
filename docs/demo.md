# Demo

Demo scenes live in this dev repo at `demo/`. They are **not** included in the packaged addon zip.

## Beginner demo — [`demo/demo.tscn`](../demo/demo.tscn)

One `VoiceSession` → one `VoiceChannel` with **Proximity** preset:

- Open mic proximity (`near_full_volume_m`, `far_silent_m`)
- Walkie enabled (`use_walkie`, `radio_push`, `VoiceRadio` bus)

The scene does not include player avatars — add `VoiceMember` on your player scenes in a real game:

```
Player
├── Head
└── VoiceMember
```

Script calls `session.start()` in `_ready` (deferred). Mirror that pattern after your lobby connects peers.

## Advanced demo — [`demo/demo_advanced.tscn`](../demo/demo_advanced.tscn)

Two channels with `allow_separate_comms = true`:

- **Proximity** — CUSTOM rules: `ProximityVolume` + open `MicMode`
- **Radio** — CUSTOM rules: PTT `MicMode`, `ChannelMembers`, `VoiceEffectsBus`

For comparison only; prefer **one** Proximity channel with `use_walkie` for walkie + proximity.

## Input actions

| Action | Default key |
|--------|-------------|
| `radio_push` | F12 |

Defined in [`project.godot`](../project.godot). Add the same action in your game's Input Map.
