# API reference

## VoiceSession

Root node. Add `VoiceChannel` children. One send and one decompress per packet unless `allow_separate_comms`.

| Member | Description |
|--------|-------------|
| `start()` | Begin voice capture and transport |
| `stop()` | End session; unbind members and clear channels |
| `@export enabled` | Master on/off |
| `@export auto_start` | Call `start()` when `get_session_peers()` is non-empty |
| `@export muffling_map` | Optional `MufflingMap` for wall muffling |
| `@export allow_separate_comms` | Allow multiple channels to each send (Advanced) |
| `set_session_peers(ids)` | Override voice recipient Steam IDs |
| `get_session_peers()` | Current list (manual or auto-discovered) |
| `get_channel(name)` | Named channel lookup |
| `get_channels()` | All registered channels |
| `get_primary_channel()` | First channel (default single-channel path) |
| `bind_member(id, head, is_local, member)` | Called by `VoiceMember` |
| `unbind_member(member)` | Called when `VoiceMember` exits tree |
| `local_steam_id` | Local Steam ID after `start()` |
| `is_active` | Session running |

Signals: `session_started`, `session_ended`, `channel_registered`, `pcm_frame_decompressed`.

Group: `voice_session` (added in `_ready`).

## VoiceMember

Per-player wiring. Discovers `VoiceSession` in the scene tree.

| Export | Description |
|--------|-------------|
| `head_path` | Voice position node (default `../Head`) |
| `steam_id` | Optional; resolved from multiplayer authority if `0` |

Methods: `get_head_node()`, `resolve_steam_id()`, `is_local_member()`.

## VoiceChannel

Direct child of `VoiceSession`. Preset builds an internal rule stack; CUSTOM uses `rules` array.

| Export | Description |
|--------|-------------|
| `channel_name` | Name for lookup and signals |
| `enabled` | Channel on/off |
| `preset` | `GLOBAL`, `PROXIMITY`, or `CUSTOM` |
| `near_full_volume_m` / `far_silent_m` | Proximity range (PROXIMITY preset → `ProximityVolume`) |
| `use_wall_muffling` | Append `WallMuffling` rule |
| `use_walkie` | Walkie PTT + effects bus on same channel |
| `push_to_talk_action` | Input action for walkie PTT |
| `effects_bus_name` | Godot audio bus for walkie playback |
| `walkie_use_channel_members` | Restrict walkie to `walkie_membership` list |
| `walkie_membership` | Steam IDs allowed on walkie (when above enabled) |
| `rules` | Custom rule stack (`CUSTOM` preset) |

Methods: `register_listener(node)`, `register_speaker(steam_id, node)`, `unregister_speaker(steam_id)`, `set_rule_enabled(class_name, enabled)`.

Signals: `speaker_registered`, `speaker_unregistered`.

## VoiceRule (Advanced)

Base class in `voice_rule.gd`. Subclass and add to `VoiceChannel.rules` when `preset = CUSTOM`.

| Rule | Role |
|------|------|
| `ProximityVolume` | Playback gain by distance (`full_volume_m`, `silent_m`, `min_volume_db`) |
| `WallMuffling` | Extra dB through walls via `VoiceSession.muffling_map` |
| `MicMode` | Send gating; `walkie_ptt_action` sets transmit flag |
| `ChannelMembers` | Restrict send/hear roster |
| `VolumeBoost` | Fixed playback dB offset |
| `VoiceEffectsBus` | Route playback to a Godot audio bus |

See [Rules](rules.md).

## Context types

**VoiceSendContext** — `compressed_voice`, `local_steam_id`, `recipients`, `transmit_flags`, `blocked`

**VoicePlaybackContext** — `listener_position`, `speaker_position`, `gain_multiplier`, `volume_db_offset`, `audio_bus`, `transmit_flags`

**VoicePacket** — `build()`, `parse()`, `payload_cache_key()`; constants `FLAG_WALKIE_ACTIVE`, `VOICE_P2P_PORT`

## MufflingMap

`from_wall_grid(wall_grid, world_to_cell_fn)` — room/cell layout for `WallMuffling`.

## SteamMultiplayerPeerAdapter

`collect_session_steam_ids(multiplayer_api)`, `get_steam_id_for_peer(peer, peer_id)` — Steam ID helpers for GodotSteam peers.
