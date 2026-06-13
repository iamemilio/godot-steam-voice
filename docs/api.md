# API reference

Public surface is global `class_name` scripts — compose nodes and resources in the editor. In-editor Help (F1) shows `##` doc comments when the addon is installed in your project.

## VoiceSession

Root node. [`voice_session.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/voice_session.gd)

### Exports

| Name | Type | Description |
|------|------|-------------|
| `enabled` | `bool` | Master enable |
| `room_graph` | `RoomGraph` | Optional level graph for occlusion |

### Signals

| Signal | Payload |
|--------|---------|
| `session_started` | — |
| `session_ended` | — |
| `channel_registered` | `VoiceChannel` |
| `pcm_frame_decompressed` | `PackedFloat32Array`, `sample_rate`, `channel_name` |

### Methods

| Method | Description |
|--------|-------------|
| `begin_session()` | Start capture and channel wiring |
| `end_session()` | Stop and tear down |
| `get_channel(name)` | Named channel lookup |
| `get_channels()` | All channels |
| `set_session_peers(ids)` | Steam IDs in the match (for roster) |
| `get_session_peers()` | Current peer list |

### State

| Property | Description |
|----------|-------------|
| `is_active` | Session running |
| `local_steam_id` | Local Steam ID after `begin_session()` |

## VoiceChannel

One comms mode per channel. [`voice_channel.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/voice_channel.gd)

### Exports

| Name | Type |
|------|------|
| `channel_name` | `String` |
| `enabled` | `bool` |
| `modifiers` | `Array[VoiceModifier]` |

### Methods

| Method | Description |
|--------|-------------|
| `register_listener(node)` | Local listener head |
| `register_speaker(steam_id, node)` | Remote speaker head |
| `unregister_speaker(steam_id)` | Remove speaker |
| `clear_speakers()` | Remove all speakers |
| `get_listener_node()` | Current listener |
| `get_speaker_node(steam_id)` | Speaker attach node |
| `get_registered_speaker_ids()` | Active speaker IDs |
| `get_modifier_by_class_name(name)` | Find modifier by class |
| `set_modifier_enabled(type_name, enabled)` | Toggle modifier |
| `get_speaker_handle(steam_id)` | Internal playback handle |

### Signals

| Signal | Payload |
|--------|---------|
| `speaker_registered` | `steam_id` |
| `speaker_unregistered` | `steam_id` |

## VoiceModifier

Base resource. [`voice_modifier.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/voice_modifier.gd)

Built-in modifiers: see [Modifiers](modifiers.md).

## Utilities

| Class | Purpose | Source |
|-------|---------|--------|
| `SteamVoiceTransport` | GodotSteam voice + P2P wrapper | [`steam_voice_transport.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/steam_voice_transport.gd) |
| `SteamMultiplayerPeerAdapter` | Peer ID → Steam ID helpers | [`adapters/steam_multiplayer_peer_adapter.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/adapters/steam_multiplayer_peer_adapter.gd) |
| `SpatialAttenuation` | Static distance gain math | [`spatial_attenuation.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/spatial_attenuation.gd) |
| `RoomGraph` | Wall/door occlusion graph | [`room_graph.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/room_graph.gd) |
| `VoiceSendContext` | Send pipeline context | [`voice_send_context.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/voice_send_context.gd) |
| `VoicePlaybackContext` | Playback pipeline context | [`voice_playback_context.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/voice_playback_context.gd) |
| `VoiceSpeakerHandle` | Per-remote-speaker playback | [`voice_speaker_handle.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/voice_speaker_handle.gd) |

## Context objects (for custom modifiers)

**VoiceSendContext** — `compressed_voice`, `local_steam_id`, `all_steam_ids`, `recipients`, `blocked`

**VoicePlaybackContext** — `listener_position`, `speaker_position`, `gain_multiplier`, `volume_db_offset`, `audio_bus`, `use_spatial_player`, `speaker_steam_id`, `session`
