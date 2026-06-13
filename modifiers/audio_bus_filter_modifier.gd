class_name AudioBusFilterModifier
extends VoiceModifier

@export var bus_name: String = "Master"


func configure_playback(ctx: VoicePlaybackContext, _speaker) -> void:
	if not bus_name.is_empty():
		ctx.audio_bus = bus_name
