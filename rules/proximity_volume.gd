class_name ProximityVolume
extends VoiceRule

## Playback volume depends on distance between players.

@export var full_volume_m: float = 3.0
@export var silent_m: float = 25.0
@export var min_volume_db: float = -40.0


func process_playback_gain(ctx: VoicePlaybackContext) -> void:
	var gain := ProximityVolumeMath.distance_gain(
		ctx.listener_position,
		ctx.speaker_position,
		full_volume_m,
		silent_m,
		min_volume_db
	)
	ctx.gain_multiplier *= gain
