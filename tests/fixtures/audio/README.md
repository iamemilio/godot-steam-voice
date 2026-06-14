# Audio test fixtures

WAV recordings for tests and manual voice pipeline checks.

**Record a fixture:**

```bash
make audio-recording
```

1. Select your microphone (watch the input level bar).
2. Press **Record**, speak, then **Stop**.
3. **Preview** the recording, then enter a filename and **Save**.
4. Select a saved file and **Play selected** (or double-click it).

All files are written to this folder (`tests/fixtures/audio/`). Do not save recordings elsewhere — tests and docs assume this path.

Use lowercase names with letters, numbers, dashes, or underscores (for example `proximity_room_tone.wav`).

Committed WAV files are listed in [../manifest.json](../manifest.json) and replayed by `tests/test_audio_fixtures.gd`.
