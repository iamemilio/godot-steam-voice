class_name SpatialAttenuationModifier
extends VoiceModifier

const AttenuationMath := preload("res://spatial_attenuation.gd")

@export var full_volume_m: float = 3.0
@export var silent_m: float = 25.0
@export var min_volume_db: float = -40.0


func configure_playback(ctx: VoicePlaybackContext, speaker) -> void:
	ctx.use_spatial_player = true
	if speaker == null:
		return
	var player = speaker.get("player")
	if player != null:
		player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED


func process_playback_gain(ctx: VoicePlaybackContext) -> void:
	var gain := AttenuationMath.distance_gain(
		ctx.listener_position,
		ctx.speaker_position,
		full_volume_m,
		silent_m,
		min_volume_db
	)
	ctx.gain_multiplier *= gain
