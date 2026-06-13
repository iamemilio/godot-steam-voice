class_name VoiceModifier
extends Resource

## Base class for stackable voice channel effects. Subclass and add to VoiceChannel.modifiers.

@export var enabled: bool = true


func on_channel_registered(_channel: Node, _session: Node) -> void:
	pass


func on_channel_unregistered() -> void:
	pass


func process_frame(_delta: float, _channel: Node, _session: Node) -> void:
	pass


func should_send(_ctx: VoiceSendContext) -> bool:
	return true


func filter_recipients(_ctx: VoiceSendContext) -> void:
	pass


func configure_playback(_ctx: VoicePlaybackContext, _speaker) -> void:
	pass


func process_playback_gain(_ctx: VoicePlaybackContext) -> void:
	pass
