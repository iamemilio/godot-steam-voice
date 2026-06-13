class_name GainModifier
extends VoiceModifier

@export var gain_db: float = 0.0


func process_playback_gain(ctx: VoicePlaybackContext) -> void:
	ctx.volume_db_offset += gain_db
