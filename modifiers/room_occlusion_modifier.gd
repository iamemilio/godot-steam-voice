class_name RoomOcclusionModifier
extends VoiceModifier

@export var closed_wall_db: float = -18.0
@export var open_door_db: float = -6.0


func process_playback_gain(ctx: VoicePlaybackContext) -> void:
	if ctx.session == null:
		return
	var room_graph = ctx.session.get("room_graph")
	if room_graph == null:
		return
	var occlusion_db: float = room_graph.get_occlusion_db(
		ctx.listener_position,
		ctx.speaker_position,
		closed_wall_db,
		open_door_db
	)
	ctx.volume_db_offset += occlusion_db
