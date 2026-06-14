class_name VoiceEffectsBus
extends VoiceRule

## Routes playback to a Godot audio bus (e.g. walkie-talkie EQ on VoiceRadio).


@export var bus_name: String = "Master"
@export var walkie_only: bool = false


func configure_playback(ctx: VoicePlaybackContext, _speaker) -> void:
	if walkie_only and (ctx.transmit_flags & VoicePacket.FLAG_WALKIE_ACTIVE) == 0:
		return
	if not bus_name.is_empty():
		ctx.audio_bus = bus_name
