# Demo

## Beginner demo — [`demo/demo.tscn`](../demo/demo.tscn)

One `VoiceChannel` with **Proximity** preset:

- Open mic proximity (`near_full_volume_m`, `far_silent_m`)
- Walkie enabled (`use_walkie`, `radio_push`, `VoiceRadio` bus)

Script calls `session.start()` when ready. Add `VoiceMember` on player scenes.

## Advanced demo — [`demo/demo_advanced.tscn`](../demo/demo_advanced.tscn)

Two channels with `allow_separate_comms = true` — separate proximity and radio comms. For comparison only; prefer one channel for walkie + proximity.

## Input actions

| Action | Default key |
|--------|-------------|
| `radio_push` | F12 |

Defined in [`project.godot`](../project.godot).
