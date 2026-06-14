# Recipes

## Global open mic

- `VoiceChannel` preset = **Global**
- One `VoiceMember` per player

## Proximity voice

- Preset = **Proximity**
- Set `near_full_volume_m` and `far_silent_m`

## Proximity + walkie (one channel)

- Preset = **Proximity**
- Enable **Walkie**: `use_walkie`, `push_to_talk_action`, `effects_bus_name`
- Create `VoiceRadio` bus in Project → Audio with EQ

Proximity and walkie share one network stream. Each client applies distance gain and walkie effects locally.

## Wall muffling

- Assign `MufflingMap` to `VoiceSession.muffling_map`
- Enable `use_wall_muffling` on the channel

## Custom rules

- Preset = **Custom**
- Add `VoiceRule` resources to `rules` array

See [Advanced](advanced.md) for separate comms channels.
