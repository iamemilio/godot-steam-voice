# GdUnit4 suite: VoiceRuntime start/stop, sibling switch, ephemeral binds, log levels.
extends GdUnitTestSuite


func _make_lobby_config() -> VoiceContextConfig:
	var cfg := VoiceContextConfig.new()
	cfg.label = &"lobby"
	cfg.binding = VoiceContextConfig.Binding.EPHEMERAL_CLUSTER
	cfg.proximity = ProximitySettings.new()
	cfg.proximity.enabled = false
	cfg.proximity.configuration = ProximityConfiguration.new()
	return cfg


func _make_game_config(
	buffer_m: float = 8.0, max_range_m: float = 40.0
) -> VoiceContextConfig:
	var cfg := VoiceContextConfig.new()
	cfg.label = &"game"
	cfg.binding = VoiceContextConfig.Binding.MEMBERS
	# VoiceContextConfig.proximity already defaults to enabled game-ready chat.
	cfg.proximity.configuration.full_volume_buffer_radius_m = buffer_m
	cfg.proximity.configuration.max_range_m = max_range_m
	return cfg


func test_default_proximity_configuration_is_game_ready() -> void:
	var cfg := VoiceContextConfig.new()
	assert_bool(cfg.is_proximity_active()).is_true()
	assert_float(cfg.proximity.configuration.full_volume_buffer_radius_m).is_equal(8.0)
	assert_float(cfg.proximity.configuration.max_range_m).is_equal(40.0)
	assert_float(cfg.proximity.configuration.max_volume_db).is_equal(0.0)
	assert_float(cfg.proximity.configuration.min_volume_db).is_equal(-40.0)


func test_start_stop_deprovisions_ephemeral() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var host := Node.new()
	auto_free(host)
	add_child(host)

	var runtime := VoiceRuntime.new()
	runtime.name = "LobbyRuntime"
	runtime.config = _make_lobby_config()
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
	assert_int(channel.preset).is_equal(VoiceChannel.Preset.GLOBAL)
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
	lobby.config = _make_lobby_config()
	host.add_child(lobby)

	var game := VoiceRuntime.new()
	game.name = "GameRuntime"
	game.config = _make_game_config(8.0, 40.0)
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
	assert_int(session.get_primary_channel().preset).is_equal(VoiceChannel.Preset.PROXIMITY)
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
	var cfg := VoiceContextConfig.new()
	cfg.binding = VoiceContextConfig.Binding.MANUAL
	cfg.proximity.enabled = false
	runtime.config = cfg
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
	var cfg := VoiceContextConfig.new()
	cfg.label = &"info"
	cfg.binding = VoiceContextConfig.Binding.MANUAL
	cfg.proximity.enabled = false
	runtime.config = cfg
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
	runtime.config = _make_game_config(8.0, 40.0)
	host.add_child(runtime)
	await await_idle_frame()

	runtime.set_peers([100, 200] as Array[int])
	runtime.start()
	assert_bool(runtime.is_active()).is_true()
	var channel := runtime.get_session().get_primary_channel()
	assert_float(channel.near_full_volume_m).is_equal(8.0)
	assert_float(channel.far_silent_m).is_equal(40.0)
	var rule := channel.get_rule_by_class_name(&"ProximityVolume") as ProximityVolume
	assert_object(rule).is_not_null()
	assert_float(rule.min_volume_db).is_equal(-40.0)
	assert_float(rule.max_volume_db).is_equal(0.0)
	runtime.stop()
