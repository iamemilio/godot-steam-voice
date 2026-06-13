# Steam voice manual smoke test

Run with two Steam clients (Spacewar app id 480 or production app id).

## Addon demo

1. Host a Steam lobby from your game menu (or a minimal test harness with GodotSteam).
2. Open `demo/demo.tscn` as a secondary scene or merge into a test main.
3. Confirm proximity (open mic) and radio (Left Shift / `radio_push`) channels in a 2-client session.

## Friend Slop maze

1. Two clients join the same lobby and start a match.
2. **Briefing:** voice at full volume (spatial modifier disabled).
3. **Active maze:** voice fades with distance and muffles through walls.
4. **Spell casting:** incantations still work on `MicCapture` (unchanged).

## Automated tests

From the addon root:

```bash
make test
```

Covers attenuation, room graph, modifier stack, and scene integration. Voice session runs in test mode (`STEAM_PROXIMITY_VOICE_TEST=1`) — no live Steam required.
