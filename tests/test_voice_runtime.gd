# GdUnit4 suite: VoiceRuntime start/stop, sibling switch, ephemeral binds, log levels.
extends GdUnitTestSuite


func _make_config(
	binding: VoiceContextConfig.Binding,
	near_m: float = 5.0,
	far_m: float = 30.0,
	label: StringName = &"test"
) -> VoiceContextConfig:
	var cfg := VoiceContextConfig.new()
	cfg.label = label
	cfg.channel_preset = VoiceChannel.Preset.PROXIMITY
	cfg.near_full_volume_m = near_m
	cfg.far_silent_m = far_m
	cfg.use_wall_muffling = false
	cfg.binding = binding
	return cfg


func test_start_stop_deprovisions_ephemeral() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var host := Node.new()
	auto_free(host)
	add_child(host)

	var runtime := VoiceRuntime.new()
	runtime.name = "LobbyRuntime"
	runtime.config = _make_config(VoiceContextConfig.Binding.EPHEMERAL_CLUSTER, 0.0, 10000.0, &"lobby")
	runtime.log_level = VoiceRuntime.LogLevel.OFF
	host.add_child(runtime)
	await await_idle_frame()

	runtime.set_peers([100, 200, 300] as Array[int])
	runtime.start()
	assert_bool(runtime.is_active()).is_true()
	var session := runtime.get_session()
	assert_object(session).is_not_null()
	assert_bool(session.is_active).is_true()
	var channel := session.get_primary_channel()
	assert_object(channel).is_not_null()
	assert_object(channel.get_listener_node()).is_not_null()
	assert_int(channel.get_registered_speaker_ids().size()).is_equal(3)

	runtime.stop()
	assert_bool(runtime.is_active()).is_false()
	assert_bool(session.is_active).is_false()
	assert_int(channel.get_registered_speaker_ids().size()).is_equal(0)


func test_starting_sibling_stops_previous() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var host := Node.new()
	auto_free(host)
	add_child(host)

	var lobby := VoiceRuntime.new()
	lobby.name = "LobbyRuntime"
	lobby.config = _make_config(VoiceContextConfig.Binding.EPHEMERAL_CLUSTER, 0.0, 10000.0, &"lobby")
	host.add_child(lobby)

	var game := VoiceRuntime.new()
	game.name = "GameRuntime"
	game.config = _make_config(VoiceContextConfig.Binding.MEMBERS, 8.0, 40.0, &"game")
	host.add_child(game)
	await await_idle_frame()

	lobby.set_peers([100, 200] as Array[int])
	lobby.start()
	assert_bool(lobby.is_active()).is_true()

	game.set_peers([100, 200] as Array[int])
	game.start()
	assert_bool(game.is_active()).is_true()
	assert_bool(lobby.is_active()).is_false()

	var session := game.get_session()
	assert_object(session).is_same(lobby.get_session())
	assert_float(session.get_primary_channel().near_full_volume_m).is_equal(8.0)
	assert_float(session.get_primary_channel().far_silent_m).is_equal(40.0)

	game.stop()
	assert_bool(game.is_active()).is_false()


func test_log_level_off_is_silent() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var host := Node.new()
	auto_free(host)
	add_child(host)

	var runtime := VoiceRuntime.new()
	runtime.config = _make_config(VoiceContextConfig.Binding.MANUAL, 5.0, 30.0, &"quiet")
	runtime.log_level = VoiceRuntime.LogLevel.OFF
	host.add_child(runtime)
	await await_idle_frame()

	var messages: Array = []
	runtime.log_message.connect(
		func(level: VoiceRuntime.LogLevel, event: String, _detail: String) -> void:
			messages.append("%s:%s" % [level, event])
	)

	runtime.set_peers([100] as Array[int])
	runtime.start()
	runtime.stop()
	assert_int(messages.size()).is_equal(0)


func test_log_level_info_emits_lifecycle() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var host := Node.new()
	auto_free(host)
	add_child(host)

	var runtime := VoiceRuntime.new()
	runtime.config = _make_config(VoiceContextConfig.Binding.MANUAL, 5.0, 30.0, &"info")
	runtime.log_level = VoiceRuntime.LogLevel.INFO
	host.add_child(runtime)
	await await_idle_frame()

	var events: Array = []
	runtime.log_message.connect(
		func(_level: VoiceRuntime.LogLevel, event: String, _detail: String) -> void:
			events.append(event)
	)

	runtime.set_peers([100] as Array[int])
	runtime.start()
	runtime.stop()
	assert_bool(events.has("started")).is_true()
	assert_bool(events.has("stopped")).is_true()


func test_members_binding_applies_channel_ranges() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var host := Node.new()
	auto_free(host)
	add_child(host)

	var runtime := VoiceRuntime.new()
	runtime.config = _make_config(VoiceContextConfig.Binding.MEMBERS, 8.0, 40.0, &"game")
	host.add_child(runtime)
	await await_idle_frame()

	runtime.set_peers([100, 200] as Array[int])
	runtime.start()
	assert_bool(runtime.is_active()).is_true()
	var channel := runtime.get_session().get_primary_channel()
	assert_float(channel.near_full_volume_m).is_equal(8.0)
	assert_float(channel.far_silent_m).is_equal(40.0)
	runtime.stop()
