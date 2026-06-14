# Integration

## Lifecycle

1. Install addon under `addons/godot-steam-voice/`.
2. Add `VoiceSession` to your level with one `VoiceChannel` child.
3. Add `VoiceMember` to each player scene (head node for voice position).
4. Call `session.start()` when peers are available.
5. Call `session.stop()` when leaving (e.g. in `_exit_tree`).

Voice runs in `VoiceSession._process` — no transport calls needed in normal use.

## VoiceMember

Attach to each player. Default exports:

| Export | Default | Purpose |
|--------|---------|---------|
| `head_path` | `../Head` | `Node3D` used for listener/speaker position |
| `steam_id` | `0` | Leave at 0 to resolve from multiplayer authority + GodotSteam peer |

`VoiceMember` walks up the scene tree to find `VoiceSession`, then calls `session.bind_member(...)`. Registration is deferred to avoid tree-order issues.

**Single-channel setup:** local member → `register_listener(head)`; remote member → `register_speaker(steam_id, head)` on the **primary** (first) channel.

**Multiple channels:** `VoiceMember` only auto-wires the primary channel. For `allow_separate_comms` setups, use manual registration (below) per channel.

## Manual registration

When not using `VoiceMember`, or when wiring multiple channels:

```gdscript
var channel := session.get_primary_channel()
channel.register_listener(local_head)
channel.register_speaker(remote_steam_id, remote_head)
```

Named channels: `session.get_channel("Radio")`.

## Multiple channels

Default: **one channel** — proximity, walkie, and wall muffling are local playback rules on one stream.

Set `VoiceSession.allow_separate_comms = true` only for intentionally separate comms (different send pipelines per channel). See [Advanced](advanced.md) and `demo/demo_advanced.tscn`.

Do **not** add a second channel just to combine proximity + walkie.

## Wall muffling

1. Build a `MufflingMap` once per level (`MufflingMap.from_wall_grid(...)`).
2. Assign to `VoiceSession.muffling_map`.
3. Enable `use_wall_muffling` on the Proximity channel.

## Session peers

By default, recipients come from GodotSteam `MultiplayerPeer` via `SteamMultiplayerPeerAdapter`. Override when needed:

```gdscript
session.set_session_peers([steam_id_a, steam_id_b])
```

## Ending a session

```gdscript
func _exit_tree() -> void:
    if session.is_active:
        session.stop()
```

`stop()` clears channels, unbinds members, and stops Steam voice capture.
