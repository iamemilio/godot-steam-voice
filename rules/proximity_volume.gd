class_name ProximityVolume
extends VoiceRule

## Distance-based voice: culls far peers on send; smooth falloff on playback.

@export var full_volume_m: float = 3.0
@export var silent_m: float = 25.0
@export var min_volume_db: float = -40.0


func filter_recipients(ctx: VoiceSendContext) -> void:
	var channel := ctx.channel as VoiceChannel
	if channel == null:
		return
	var local_node := channel.get_listener_node()
	if local_node == null or not is_instance_valid(local_node):
		return
	var speaker_pos := local_node.global_position
	var filtered: Array[int] = []
	for steam_id in ctx.recipients:
		var recipient_id := int(steam_id)
		var recipient_node := channel.get_speaker_node(recipient_id)
		if recipient_node == null or not is_instance_valid(recipient_node):
			filtered.append(recipient_id)
			continue
		if ProximityVolumeMath.is_audible_distance(
			speaker_pos, recipient_node.global_position, silent_m
		):
			filtered.append(recipient_id)
	ctx.recipients = filtered


func process_playback_gain(ctx: VoicePlaybackContext) -> void:
	var gain := ProximityVolumeMath.distance_gain(
		ctx.listener_position,
		ctx.speaker_position,
		full_volume_m,
		silent_m,
		min_volume_db
	)
	ctx.gain_multiplier *= gain
