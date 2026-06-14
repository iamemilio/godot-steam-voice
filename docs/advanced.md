# Advanced

## Custom rules

Set `VoiceChannel.preset = CUSTOM` and assign `rules: Array[VoiceRule]`.

Subclass `VoiceRule` and override send/playback hooks. See [`rules/`](../rules/) and [Rules](rules.md).

**MicMode** fields for CUSTOM stacks:

- `open_mic_enabled` / `input_mode` / `input_action` — main mic gating
- `walkie_ptt_action` — sets `VoicePacket.FLAG_WALKIE_ACTIVE` when held (used by Proximity preset walkie)

## Separate comms channels

Only when you need **independent** voice networks (different audiences, simultaneous modes):

```gdscript
# On VoiceSession
allow_separate_comms = true
```

Add multiple `VoiceChannel` children. Each channel can send per frame when its rules allow.

See [`demo/demo_advanced.tscn`](../demo/demo_advanced.tscn) — Proximity and Radio channels with CUSTOM rules.

Default is **one channel** — do not add a second channel for walkie + proximity on the same audience.

**VoiceMember** auto-registers only on the **primary** (first) channel. Multi-channel games must call `register_listener` / `register_speaker` on each channel explicitly.

## MufflingMap

```gdscript
session.muffling_map = MufflingMap.from_wall_grid(wall_grid, world_to_cell_fn)
```

Enable `use_wall_muffling` on a Proximity channel (or add `WallMuffling` in CUSTOM).

## ChannelMembers callable

```gdscript
var members := ChannelMembers.new()
members.membership_fn = func() -> Array[int]:
    return my_steam_id_list
```

Or use preset exports `walkie_use_channel_members` / `walkie_membership` for walkie-only rosters.

## Transmit flags

Packets include a flags byte (`VoicePacket.FLAG_WALKIE_ACTIVE`). Playback rules read `VoicePlaybackContext.transmit_flags` (e.g. `VoiceEffectsBus.walkie_only`).

## set_session_peers

```gdscript
session.set_session_peers([steam_id_a, steam_id_b])
```

Optional when auto peer sync from GodotSteam `MultiplayerPeer` is sufficient.
