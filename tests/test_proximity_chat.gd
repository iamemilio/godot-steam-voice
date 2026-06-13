# GdUnit4 suite: proximity channel (open mic + spatial + room occlusion).
extends GdUnitTestSuite


func _make_wall_grid() -> Array:
	var grid: Array = []
	for x in 5:
		var row: Array = []
		for y in 5:
			row.append(1)
		grid.append(row)
	grid[1][1] = 0
	grid[3][1] = 0
	grid[2][1] = 1
	return grid


func test_open_mic_allows_send_without_input_modifier() -> void:
	var channel: VoiceChannel = auto_free(VoiceChannel.new())
	var ctx := VoiceSendContext.new()
	ctx.compressed_voice = PackedByteArray([1, 2, 3])
	ctx.local_steam_id = 100
	ctx.recipients = [100, 200]
	assert_bool(channel.evaluate_send(ctx)).is_true()


func test_proximity_spatial_and_occlusion_reduce_volume_through_walls() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var session := VoiceSession.new()
	auto_free(session)
	var channel := VoiceChannel.new()
	var spatial := SpatialAttenuationModifier.new()
	spatial.full_volume_m = 3.0
	spatial.silent_m = 25.0
	var occlusion := RoomOcclusionModifier.new()
	channel.modifiers = [spatial, occlusion]
	session.add_child(channel)

	var grid := _make_wall_grid()
	session.room_graph = RoomGraph.from_wall_grid(
		grid,
		func(pos: Vector3) -> Vector2i:
			if pos.x < 0.5:
				return Vector2i(1, 1)
			return Vector2i(3, 1)
	)
	add_child(session)
	await await_idle_frame()
	session.setup_offline_session_for_tests()

	var listener := Node3D.new()
	var speaker := Node3D.new()
	auto_free(listener)
	auto_free(speaker)
	listener.position = Vector3(-1.0, 0.0, 0.0)
	speaker.position = Vector3(1.0, 0.0, 0.0)
	add_child(listener)
	add_child(speaker)

	channel.register_listener(listener)
	channel.register_speaker(42, speaker)
	channel.get_or_create_handle(42)
	channel.update_playback()
	var muffled_db := channel.get_speaker_handle(42).player.volume_db

	listener.position = Vector3(0.0, 0.0, 0.0)
	speaker.position = Vector3(1.0, 0.0, 0.0)
	session.room_graph = RoomGraph.from_wall_grid(
		grid,
		func(_pos: Vector3) -> Vector2i:
			return Vector2i(1, 1)
	)
	channel.update_playback()
	var same_room_db := channel.get_speaker_handle(42).player.volume_db

	assert_float(muffled_db).is_less(same_room_db)


func test_speaker_position_updates_change_gain() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var session := VoiceSession.new()
	auto_free(session)
	var channel := VoiceChannel.new()
	var spatial := SpatialAttenuationModifier.new()
	spatial.full_volume_m = 3.0
	spatial.silent_m = 25.0
	channel.modifiers = [spatial]
	session.add_child(channel)
	add_child(session)
	await await_idle_frame()
	session.setup_offline_session_for_tests()

	var listener := Node3D.new()
	var speaker := Node3D.new()
	auto_free(listener)
	auto_free(speaker)
	add_child(listener)
	add_child(speaker)
	channel.register_listener(listener)
	channel.register_speaker(7, speaker)
	channel.get_or_create_handle(7)

	speaker.position = Vector3(20.0, 0.0, 0.0)
	channel.update_playback()
	var far_db := channel.get_speaker_handle(7).player.volume_db

	speaker.position = Vector3(1.0, 0.0, 0.0)
	channel.update_playback()
	var near_db := channel.get_speaker_handle(7).player.volume_db

	assert_float(near_db).is_greater(far_db)
