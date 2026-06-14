class_name VolumeBoost
extends VoiceRule

## Adds a fixed dB offset to playback volume.


@export var gain_db: float = 0.0


func process_playback_gain(ctx: VoicePlaybackContext) -> void:
	ctx.volume_db_offset += gain_db
