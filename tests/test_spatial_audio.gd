# GdUnit4 suite: spatial audio distance math and playback wiring.
extends GdUnitTestSuite


func test_full_gain_inside_radius() -> void:
	var gain := SpatialAttenuation.distance_gain(
		Vector3.ZERO, Vector3(2.0, 0.0, 0.0), 3.0, 25.0, -40.0
	)
	assert_float(gain).is_equal_approx(1.0, 0.001)


func test_silent_beyond_radius() -> void:
	var gain := SpatialAttenuation.distance_gain(
		Vector3.ZERO, Vector3(30.0, 0.0, 0.0), 3.0, 25.0, -40.0
	)
	assert_float(gain).is_less(0.02)


func test_mid_range_partial_gain() -> void:
	var gain := SpatialAttenuation.distance_gain(
		Vector3.ZERO, Vector3(14.0, 0.0, 0.0), 3.0, 25.0, -40.0
	)
	assert_float(gain).is_less(1.0)
	assert_float(gain).is_greater(0.02)


func test_distance_gain_db_matches_linear_gain() -> void:
	var gain := SpatialAttenuation.distance_gain(
		Vector3.ZERO, Vector3(14.0, 0.0, 0.0), 3.0, 25.0, -40.0
	)
	var gain_db := SpatialAttenuation.distance_gain_db(
		Vector3.ZERO, Vector3(14.0, 0.0, 0.0), 3.0, 25.0, -40.0
	)
	assert_float(gain_db).is_equal_approx(linear_to_db(maxf(gain, 0.00001)), 0.01)


func test_spatial_modifier_sets_use_spatial_player() -> void:
	var spatial := SpatialAttenuationModifier.new()
	var ctx := VoicePlaybackContext.new()
	ctx.listener_position = Vector3.ZERO
	ctx.speaker_position = Vector3(2.0, 0.0, 0.0)
	spatial.process_playback_gain(ctx)
	assert_float(ctx.gain_multiplier).is_equal_approx(1.0, 0.001)


func test_speaker_handle_disables_engine_attenuation() -> void:
	var parent := Node3D.new()
	auto_free(parent)
	add_child(parent)
	var handle := VoiceSpeakerHandle.new()
	handle.setup(parent, 42, parent)
	assert_object(handle.player).is_not_null()
	assert_int(handle.player.attenuation_model).is_equal(
		AudioStreamPlayer3D.ATTENUATION_DISABLED
	)


func test_gain_stack_multiplies() -> void:
	var spatial := SpatialAttenuationModifier.new()
	spatial.full_volume_m = 3.0
	spatial.silent_m = 25.0
	var gain_mod := GainModifier.new()
	gain_mod.gain_db = -6.0
	var ctx := VoicePlaybackContext.new()
	ctx.listener_position = Vector3.ZERO
	ctx.speaker_position = Vector3(2, 0, 0)
	spatial.process_playback_gain(ctx)
	gain_mod.process_playback_gain(ctx)
	assert_float(ctx.gain_multiplier).is_greater(0.99)
	assert_float(ctx.volume_db_offset).is_less(-5.5)


func test_spatial_playback_with_registered_speakers() -> void:
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
	listener.position = Vector3.ZERO
	speaker.position = Vector3(30.0, 0.0, 0.0)
	add_child(listener)
	add_child(speaker)

	channel.register_listener(listener)
	channel.register_speaker(42, speaker)
	channel.get_or_create_handle(42)
	channel.update_playback()

	var handle := channel.get_speaker_handle(42)
	assert_object(handle).is_not_null()
	assert_object(handle.player).is_not_null()
	assert_float(handle.player.volume_db).is_less(-10.0)

	speaker.position = Vector3(2.0, 0.0, 0.0)
	channel.update_playback()
	assert_float(handle.player.volume_db).is_greater(-3.0)
