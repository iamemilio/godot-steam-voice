# Demo

Demo scenes live in this dev repo at `demo/`. They are **not** included in the packaged addon zip.

## VoiceRuntime demo — [`demo/demo_runtime.tscn`](../demo/demo_runtime.tscn)

Two Inspector-configured `VoiceRuntime` nodes:

- **LobbyRuntime** — `EPHEMERAL_CLUSTER`, huge `far_silent_m`
- **GameRuntime** — `MEMBERS`, 8m / 40m proximity

Keys: `1` lobby, `2` game, `0` stop, `L` cycle log level.

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

For comparison only; prefer **one** Proximity channel with `use_walkie` for walkie + proximity, or `VoiceRuntime` for lobby/match switching.

## Input actions

| Action | Default key |
|--------|-------------|
| `radio_push` | F12 |

Defined in [`project.godot`](../project.godot). Add the same action in your game's Input Map.
