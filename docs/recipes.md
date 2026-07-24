# Recipes

Assumes addon at `addons/godot-steam-voice/`. Prefer **`VoiceRuntime`** nodes for lobby vs match setups; use raw `VoiceSession` when you need full manual control.

## Lobby chat + in-game proximity (VoiceRuntime)

```
VoiceHost
├── LobbyRuntime     binding = EPHEMERAL_CLUSTER, proximity.enabled = false
└── GameRuntime      binding = MEMBERS, proximity enabled with defaults (8m / 40m)
```

`VoiceContextConfig.new()` already includes game-ready proximity. For lobby, only flip `proximity.enabled = false`.

```gdscript
lobby_runtime.set_peers(ids)
lobby_runtime.start()
# ...
lobby_runtime.stop()
game_runtime.set_peers(ids)
game_runtime.start()
```

Players need `VoiceMember` on heads for `GameRuntime`. Lobby uses ephemeral anchors — no heads required.

## Debug logging

Set `log_level` on the runtime (Inspector or `set_log_level`):

| Level | Behavior |
|-------|----------|
| `OFF` | Quiet |
| `INFO` | start/stop lifecycle |
| `DEBUG` | INFO + session `voice_debug` + throttled heartbeat |

Connect `log_message` to route into your own logger, or rely on `[godot-steam-voice]` prints.

## Global open mic

- `VoiceChannel` preset = **Global**
- One `VoiceMember` per player
- `session.start()` when peers are ready

## Proximity voice

- Preset = **Proximity**
- Tune `near_full_volume_m` and `far_silent_m`
- Open mic transmits to all session peers; volume is adjusted locally by distance

## Proximity + walkie (one channel)

- Preset = **Proximity**
- Enable **Walkie**: `use_walkie`, `push_to_talk_action`, `effects_bus_name`
- Create `VoiceRadio` bus in Project → Audio with EQ

Open-mic proximity and walkie PTT share **one** network send. The sender culls peers beyond `far_silent_m`; receivers still apply smooth distance falloff on every packet. The effects bus applies only when the sender held walkie PTT (`FLAG_WALKIE_ACTIVE`).

## Wall muffling

- Build `MufflingMap` and assign to `VoiceSession.muffling_map`
- Preset = **Proximity**, enable `use_wall_muffling`

## Walkie-only group (still one channel)

- Preset = **Proximity** with `use_walkie`
- Enable `walkie_use_channel_members` and fill `walkie_membership` with allowed Steam IDs

Non-members still hear open-mic proximity; walkie PTT is restricted to the roster.

## Custom rules

- Preset = **Custom**
- Add `VoiceRule` resources to the `rules` array

See [Advanced](advanced.md) for separate comms channels (rare).
