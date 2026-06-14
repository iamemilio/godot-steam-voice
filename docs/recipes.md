# Recipes

Assumes addon at `addons/godot-steam-voice/`, one `VoiceSession`, and `VoiceMember` on each player (`head_path` → head `Node3D`).

## Global open mic

- `VoiceChannel` preset = **Global**
- One `VoiceMember` per player
- `session.start()` when peers are ready

## Proximity voice

- Preset = **Proximity**
- Tune `near_full_volume_m` and `far_silent_m`
- Open mic transmits to all session peers; volume is adjusted locally by distance

## Proximity + walkie (one channel)

- Preset = **Proximity**
- Enable **Walkie**: `use_walkie`, `push_to_talk_action`, `effects_bus_name`
- Create `VoiceRadio` bus in Project → Audio with EQ

Open-mic proximity and walkie PTT share **one** network send. Receivers apply distance gain on every packet; the effects bus applies only when the sender held walkie PTT (`FLAG_WALKIE_ACTIVE`).

## Wall muffling

- Build `MufflingMap` and assign to `VoiceSession.muffling_map`
- Preset = **Proximity**, enable `use_wall_muffling`

## Walkie-only group (still one channel)

- Preset = **Proximity** with `use_walkie`
- Enable `walkie_use_channel_members` and fill `walkie_membership` with allowed Steam IDs

Non-members still hear open-mic proximity; walkie PTT is restricted to the roster.

## Custom rules

- Preset = **Custom**
- Add `VoiceRule` resources to the `rules` array

See [Advanced](advanced.md) for separate comms channels (rare).
