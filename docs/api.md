# API reference

## Simple API

### VoiceSession

| Member | Description |
|--------|-------------|
| `start()` | Begin voice capture and transport |
| `stop()` | End session |
| `@export auto_start` | Start when peers are available |
| `@export muffling_map` | Optional `MufflingMap` for wall muffling |
| `@export allow_separate_comms` | Allow multiple `VoiceChannel` children (Advanced) |
| `set_session_peers(ids)` | Voice recipient Steam IDs |
| `get_session_peers()` | Current recipient list |
| `get_channel(name)` | Named channel lookup |
| `get_primary_channel()` | First channel (default path) |
| `local_steam_id` | Local Steam ID after `start()` |
| `is_active` | Session running |

Signals: `session_started`, `session_ended`, `channel_registered`, `pcm_frame_decompressed`.

### VoiceMember

| Export | Description |
|--------|-------------|
| `head_path` | Voice position node (usually `Head`) |
| `steam_id` | Optional; resolved from multiplayer if 0 |

### VoiceChannel

| Export | Description |
|--------|-------------|
| `preset` | `GLOBAL`, `PROXIMITY`, or `CUSTOM` |
| `near_full_volume_m` / `far_silent_m` | Proximity range (PROXIMITY preset) |
| `use_wall_muffling` | Enable wall muffling |
| `use_walkie` | Enable walkie toggles on same channel |
| `push_to_talk_action` | Walkie PTT input action |
| `effects_bus_name` | Godot audio bus for walkie EQ |
| `rules` | Custom rule stack (`CUSTOM` preset) |

Methods: `set_rule_enabled(type_name, enabled)`.

## Rules reference (Advanced)

| Rule | Contract |
|------|----------|
| `ProximityVolume` | Volume follows distance |
| `WallMuffling` | Quieter through walls |
| `MicMode` | Open mic / PTT; sets transmit flags |
| `ChannelMembers` | Restricts talk/hear roster |
| `VolumeBoost` | Fixed dB offset |
| `VoiceEffectsBus` | Routes to a Godot audio bus |

## Context types

**VoiceSendContext** — `compressed_voice`, `local_steam_id`, `recipients`, `transmit_flags`

**VoicePlaybackContext** — positions, `gain_multiplier`, `audio_bus`, `transmit_flags`

**VoicePacket** — envelope helpers; `FLAG_WALKIE_ACTIVE`, `VOICE_P2P_PORT`
