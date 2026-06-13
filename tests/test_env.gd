class_name VoiceTestEnv
extends RefCounted

## Headless test runs for steam_proximity_voice — no Steam client required.

const ENV_KEY := "STEAM_PROXIMITY_VOICE_TEST"


static func is_active() -> bool:
	return OS.get_environment(ENV_KEY) == "1"


static func ensure_active() -> void:
	if not is_active():
		OS.set_environment(ENV_KEY, "1")
