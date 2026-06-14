extends Node3D

## Advanced demo: separate comms channels (requires allow_separate_comms).

@onready var session: VoiceSession = $VoiceSession


func _ready() -> void:
	if OS.get_environment("STEAM_PROXIMITY_VOICE_TEST") == "1":
		return
	call_deferred("_start_voice")


func _start_voice() -> void:
	session.start()


func _exit_tree() -> void:
	if session != null and session.is_active:
		session.stop()
