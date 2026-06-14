class_name VoiceSessionTestSupport
extends RefCounted

## Test-only helpers — not part of the public game integration API.


static func activate_offline(session: VoiceSession, local_id: int = 100) -> void:
	if OS.get_environment("STEAM_PROXIMITY_VOICE_TEST") != "1":
		return
	session._discover_channels()
	if session._channels.is_empty():
		return
	session._allocate_channel_ids()
	session.local_steam_id = local_id
	session.is_active = true


static func set_transport(session: VoiceSession, transport: RefCounted) -> void:
	if OS.get_environment("STEAM_PROXIMITY_VOICE_TEST") != "1":
		return
	session._transport = transport


static func run_frame(session: VoiceSession, delta: float = 0.0) -> void:
	if OS.get_environment("STEAM_PROXIMITY_VOICE_TEST") != "1" or not session.is_active:
		return
	session._tick_frame(delta)
