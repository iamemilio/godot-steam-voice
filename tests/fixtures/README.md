# Test fixtures

Golden assets for regression tests. See [manifest.json](manifest.json) for metadata.

## Audio (`audio/`)

WAV recordings captured with `make audio-recording`. Tests load these headlessly via `VoiceFixtureLoader` and replay PCM through `FakeSteamVoiceTransport` and `VoiceSpeakerHandle`.

See [audio/README.md](audio/README.md) for recording instructions.
