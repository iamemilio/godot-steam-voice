class_name WallMuffling
extends VoiceRule

## Reduces playback volume when listener and speaker are separated by walls.


@export var closed_wall_db: float = -18.0
@export var open_door_db: float = -6.0


func process_playback_gain(ctx: VoicePlaybackContext) -> void:
	var session := ctx.session as VoiceSession
	if session == null or session.muffling_map == null:
		return
	var muffling_map: MufflingMap = session.muffling_map
	var occlusion_db: float = muffling_map.get_occlusion_db(
		ctx.listener_position,
		ctx.speaker_position,
		closed_wall_db,
		open_door_db
	)
	ctx.volume_db_offset += occlusion_db
