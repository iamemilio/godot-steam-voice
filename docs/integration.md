# Integration

## Lifecycle

1. Add `VoiceSession` to your scene with one or more `VoiceChannel` children.
2. When your multiplayer match is ready, call `session.set_session_peers(steam_ids)` if you use roster filtering.
3. Call `session.begin_session()` — starts Steam voice capture and channel wiring.
4. Register the local listener and remote speakers on each channel you use.
5. Call `session.end_session()` when leaving the match (e.g. in `_exit_tree`).

The session runs capture/send/receive in `_process`. You do not call transport APIs directly in normal use.

## Registering participants

```gdscript
channel.register_listener(local_head_node)           # one listener per channel
channel.register_speaker(remote_steam_id, head_node) # one per remote player
channel.unregister_speaker(remote_steam_id)
```

Use the same head `Node3D` for listener and speakers on a channel. The addon attaches playback to speaker head nodes and reads positions every frame.

## Steam ID helpers

[`SteamMultiplayerPeerAdapter`](https://github.com/iamemilio/godot-steam-voice/blob/main/adapters/steam_multiplayer_peer_adapter.gd) resolves GodotSteam multiplayer peer IDs to Steam IDs:

```gdscript
var steam_id := SteamMultiplayerPeerAdapter.get_steam_id_for_peer(peer, peer_id)
var ids := SteamMultiplayerPeerAdapter.collect_session_steam_ids(multiplayer)
session.set_session_peers(ids)
```

Bulk registration from a player root:

```gdscript
SteamMultiplayerPeerAdapter.register_players_from_tree(
    channel,
    players_root,
    NodePath("Head"),
    func(player): return get_steam_id_for(player)
)
```

Demo usage: [`demo/demo.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/demo/demo.gd).

## Multiple channels

Each `VoiceChannel` gets its own wire ID and Steam P2P port automatically. Stack different modifier sets per channel — e.g. proximity (open mic + spatial) and radio (PTT + roster + bus filter) in parallel.

Register the same head nodes on each channel you want a player to hear or speak on.

## Room occlusion

Assign a `RoomGraph` resource to `VoiceSession.room_graph` and add `RoomOcclusionModifier` to a proximity channel.

Build the graph once per level:

```gdscript
session.room_graph = RoomGraph.from_wall_grid(wall_grid, world_to_cell_fn)
```

`world_to_cell` maps `Vector3` world positions to grid cells. See [`tests/test_room_graph.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/tests/test_room_graph.gd) and [`tests/test_proximity_chat.gd`](https://github.com/iamemilio/godot-steam-voice/blob/main/tests/test_proximity_chat.gd).

## Radio audio bus

`RadioFilterModifier` routes playback to the **`VoiceRadio`** audio bus. Create that bus in Project → Audio and add EQ / band-pass / distortion there. The modifier only sets routing — DSP lives on the bus.

## Ending a session

```gdscript
func _exit_tree() -> void:
    if session.is_active:
        session.end_session()
```
