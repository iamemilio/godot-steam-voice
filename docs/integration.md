# Integration

## Lifecycle

1. Add `VoiceSession` with one `VoiceChannel` child.
2. Add `VoiceMember` to each player (head node for voice position).
3. Call `session.start()` when peers are available.
4. Call `session.stop()` when leaving (e.g. in `_exit_tree`).

Voice runs in `_process` — no transport calls needed in normal use.

## VoiceMember

```gdscript
# On each player scene:
# VoiceMember  head_path = Head
```

Session discovers members and registers listener (local) or speaker (remote) on the voice channel.

## Advanced registration

```gdscript
channel.register_listener(local_head)
channel.register_speaker(remote_steam_id, head)
```

## Multiple channels

Default: **one channel** — proximity, walkie, and wall muffling are local playback rules on one stream.

Set `VoiceSession.allow_separate_comms = true` only for intentionally separate comms (see [Advanced](advanced.md) and `demo/demo_advanced.tscn`).

## Wall muffling

1. Build a `MufflingMap` once per level.
2. Assign to `VoiceSession.muffling_map`.
3. Enable `use_wall_muffling` on the channel.

## Ending a session

```gdscript
func _exit_tree() -> void:
    if session.is_active:
        session.stop()
```
