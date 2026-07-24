# API reference

## VoiceRuntime

High-level Node. Configure a `VoiceContextConfig` in the Inspector, then `start()` / `stop()` from code. Sibling runtimes under the same parent share one `VoiceSession`; only one may be active.

| Member | Description |
|--------|-------------|
| `@export config` | `VoiceContextConfig` blueprint (binding + proximity) |
| `@export log_level` | `OFF`, `INFO`, or `DEBUG` |
| `@export heartbeat_interval_msec` | DEBUG heartbeat period (default 2000) |
| `start()` | Apply config, start shared session, bind speakers |
| `stop()` | Full deprovision (session stop, free ephemeral anchors) |
| `refresh()` | Re-apply peers and binding while active |
| `set_peers(ids)` | Steam IDs for the voice roster |
| `get_session()` | Underlying `VoiceSession` (created if needed) |
| `set_log_level` / `get_log_level` | Runtime logging control |
| `is_active()` | This runtime owns the live session |

Signals: `started`, `stopped`, `log_message(level, event, detail)`.

Prints use the prefix `[godot-steam-voice]`.

## VoiceContextConfig

Resource assigned to `VoiceRuntime.config`. **New Resource** ships game-ready proximity defaults (8m buffer / 40m range).

| Export | Description |
|--------|-------------|
| `label` | Optional name for logs |
| `binding` | `MEMBERS`, `EPHEMERAL_CLUSTER`, or `MANUAL` |
| `proximity` | `ProximitySettings` (nested; see below) |

| Binding | Behavior |
|---------|----------|
| `MEMBERS` | `VoiceMember` heads via `refresh_member_bindings()` |
| `EPHEMERAL_CLUSTER` | Runtime-owned anchors at origin (lobby-style) |
| `MANUAL` | Game registers listener/speakers on the channel |

## ProximitySettings / ProximityConfiguration

```
proximity
├── enabled              default true
└── configuration        default game-ready values
    ├── max_volume_db
    ├── min_volume_db
    ├── full_volume_buffer_radius_m
    ├── max_range_m
    ├── decay            LINEAR_DB
    └── use_wall_muffling
```

| Default | Value |
|---------|-------|
| `enabled` | `true` |
| `full_volume_buffer_radius_m` | `8` |
| `max_range_m` | `40` |
| `max_volume_db` | `0` |
| `min_volume_db` | `-40` |

Set `proximity.enabled = false` for lobby open mic (no distance fade). Inside the buffer radius volume stays at max; between buffer and max range it decays toward min; past max range peers are not sent to.

## VoiceSession

Root node. Add `VoiceChannel` children. One send and one decompress per packet unless `allow_separate_comms`. `VoiceRuntime` manages this for you when using the high-level API.

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
