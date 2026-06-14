# Advanced

## Custom rules

Set `VoiceChannel.preset = CUSTOM` and assign `rules: Array[VoiceRule]`.

Subclass `VoiceRule` and override send/playback hooks.

## Separate comms channels

Only when you need **independent** voice networks (different audiences, simultaneous modes):

```gdscript
@export var allow_separate_comms = true  # on VoiceSession
```

See [`demo/demo_advanced.tscn`](../demo/demo_advanced.tscn).

Default is **one channel** — do not add a second channel for walkie + proximity.

## MufflingMap

```gdscript
session.muffling_map = MufflingMap.from_wall_grid(wall_grid, world_to_cell_fn)
```

## ChannelMembers callable

```gdscript
var members := ChannelMembers.new()
members.membership_fn = func() -> Array[int]:
    return my_steam_id_list
```

## Transmit flags

Packets include a flags byte (`VoicePacket.FLAG_WALKIE_ACTIVE`). Playback rules use `VoicePlaybackContext.transmit_flags`.

## set_session_peers

```gdscript
session.set_session_peers([steam_id_a, steam_id_b])
```

Optional when auto peer sync from Godot multiplayer is sufficient.
