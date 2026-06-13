# Modifiers

Modifiers are `VoiceModifier` resources stacked on a `VoiceChannel`. They hook into send gating, recipient filtering, and playback gain/routing.

Disable any modifier at runtime with `channel.set_modifier_enabled("SpatialAttenuationModifier", false)`.

## Send-side

### VoiceInputModifier

Controls whether the local player transmits on this channel.

| Export | Default | Description |
|--------|---------|-------------|
| `input_mode` | `OPEN_MIC` | `OPEN_MIC` or `PUSH_TO_TALK` |
| `input_action` | `"voice_push"` | Input Map action for PTT |

**Demo:** [Radio channel PTT](https://github.com/iamemilio/godot-steam-voice/blob/main/demo/demo.tscn#L16-L19) · **Tests:** [`test_multiplayer_voice.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/tests/test_multiplayer_voice.gd)

### RosterModifier

Restricts who can send to and hear whom on a channel.

| Export | Description |
|--------|-------------|
| `membership` | Static list of Steam IDs |
| `membership_fn` | Callable returning `Array[int]` — preferred for dynamic lobbies |

When membership is empty, roster filtering is a no-op (everyone allowed).

**Demo:** [`demo/demo.gd` `_configure_radio_roster()`](https://github.com/iamemilio/godot-steam-voice/blob/main/demo/demo.gd#L20-L27) · **Tests:** [`test_demo_scene.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/tests/test_demo_scene.gd)

## Playback-side

### SpatialAttenuationModifier

Distance-based volume using listener and speaker head positions. Disables Godot's built-in `AudioStreamPlayer3D` attenuation and applies custom gain math instead.

| Export | Default | Description |
|--------|---------|-------------|
| `full_volume_m` | `3.0` | Full volume within this radius (m) |
| `silent_m` | `25.0` | Effectively silent beyond this radius (m) |
| `min_volume_db` | `-40.0` | Floor in dB |

**Demo:** [Proximity channel](https://github.com/iamemilio/godot-steam-voice/blob/main/demo/demo.tscn#L11-L14) · **Tests:** [`test_spatial_audio.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/tests/test_spatial_audio.gd), [`test_proximity_chat.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/tests/test_proximity_chat.gd)

### RoomOcclusionModifier

Muffles voice across walls/doors using `VoiceSession.room_graph`.

| Export | Default | Description |
|--------|---------|-------------|
| `closed_wall_db` | `-18.0` | Attenuation when separated by a wall |
| `open_door_db` | `-6.0` | Attenuation through an open door between rooms |

Requires a `RoomGraph` on the session. Not shown in the demo scene.

**Tests:** [`test_room_graph.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/tests/test_room_graph.gd), [`test_proximity_chat.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/tests/test_proximity_chat.gd)

### GainModifier

Fixed dB offset on playback.

| Export | Default |
|--------|---------|
| `gain_db` | `0.0` |

**Source:** [`modifiers/gain_modifier.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/modifiers/gain_modifier.gd)

### AudioBusFilterModifier

Routes remote speaker playback to a Godot audio bus (for EQ, compression, etc. in Project → Audio).

| Export | Default |
|--------|---------|
| `bus_name` | `"Master"` |

**Source:** [`modifiers/audio_bus_filter_modifier.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/modifiers/audio_bus_filter_modifier.gd)

### RadioFilterModifier

Preset of `AudioBusFilterModifier` with `bus_name = "VoiceRadio"`. Walkie-talkie style routing — add effects on the `VoiceRadio` bus.

**Demo:** [Radio channel](https://github.com/iamemilio/godot-steam-voice/blob/main/demo/demo.tscn#L24-L25) · **Source:** [`modifiers/radio_filter_modifier.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/modifiers/radio_filter_modifier.gd)

## Custom modifiers

Subclass [`VoiceModifier`](https://github.com/iamemilio/godot-steam-voice/blob/main/voice_modifier.gd) and override:

| Hook | Purpose |
|------|---------|
| `should_send(ctx)` | Gate transmission |
| `filter_recipients(ctx)` | Shrink `ctx.recipients` |
| `process_playback_gain(ctx)` | Volume / distance / occlusion |
| `configure_playback(ctx, speaker)` | Bus routing, player setup |
| `process_frame(delta, channel, session)` | Per-frame logic (e.g. PTT polling) |

Add your resource to `VoiceChannel.modifiers` in the Inspector.

## Typical stacks

| Channel | Modifiers | Use case |
|---------|-----------|----------|
| Proximity | `SpatialAttenuationModifier`, `RoomOcclusionModifier` | Mumble-style local chat |
| Radio | `VoiceInputModifier` (PTT), `RosterModifier`, `RadioFilterModifier` | Squad radio |
| Global | *(none)* | Everyone hears everyone, always |
