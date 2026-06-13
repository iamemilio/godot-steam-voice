# GdUnit4 suite: multiplayer voice session, channels, and packet pipeline.
extends GdUnitTestSuite


func test_channel_auto_allocation() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var session := VoiceSession.new()
	auto_free(session)
	var proximity := VoiceChannel.new()
	proximity.channel_name = "Proximity"
	var radio := VoiceChannel.new()
	radio.channel_name = "Radio"
	session.add_child(proximity)
	session.add_child(radio)
	add_child(session)
	await await_idle_frame()

	session.setup_offline_session_for_tests()
	assert_int(proximity.wire_id).is_equal(1)
	assert_int(proximity.p2p_port).is_equal(1)
	assert_int(radio.wire_id).is_equal(2)
	assert_int(radio.p2p_port).is_equal(2)


func test_get_channel_by_name() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var session := VoiceSession.new()
	auto_free(session)
	var proximity := VoiceChannel.new()
	proximity.channel_name = "Proximity"
	session.add_child(proximity)
	add_child(session)
	await await_idle_frame()
	session.setup_offline_session_for_tests()
	assert_object(session.get_channel("Proximity")).is_same(proximity)


func test_multi_channel_send_uses_distinct_p2p_ports() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var transport := FakeSteamVoiceTransport.new()
	var session := VoiceSession.new()
	auto_free(session)
	var proximity := VoiceChannel.new()
	var radio := VoiceChannel.new()
	session.add_child(proximity)
	session.add_child(radio)
	add_child(session)
	await await_idle_frame()
	session.set_transport_for_tests(transport)
	session.setup_offline_session_for_tests(100)
	session.set_session_peers([200])
	transport.set_voice(PackedByteArray([1, 2, 3]))
	session.run_frame_for_tests()
	assert_int(transport.sent_packets.size()).is_equal(2)
	var ports: Array[int] = []
	for packet in transport.sent_packets:
		ports.append(int(packet["p2p_port"]))
	assert_int(ports[0]).is_not_equal(ports[1])


func test_send_packet_prefixes_wire_id() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var transport := FakeSteamVoiceTransport.new()
	var session := VoiceSession.new()
	auto_free(session)
	var channel := VoiceChannel.new()
	session.add_child(channel)
	add_child(session)
	await await_idle_frame()
	session.set_transport_for_tests(transport)
	session.setup_offline_session_for_tests(100)
	session.set_session_peers([200])
	transport.set_voice(PackedByteArray([9, 8, 7]))
	session.run_frame_for_tests()
	assert_int(transport.sent_packets.size()).is_equal(1)
	var packet: PackedByteArray = transport.sent_packets[0]["data"]
	assert_int(packet[0]).is_equal(1)
	assert_int(packet[1]).is_equal(9)
	assert_int(packet[2]).is_equal(8)
	assert_int(packet[3]).is_equal(7)


func test_receive_pushes_pcm_to_speaker_handle() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var transport := FakeSteamVoiceTransport.new()
	var session := VoiceSession.new()
	auto_free(session)
	var channel := VoiceChannel.new()
	session.add_child(channel)
	add_child(session)
	await await_idle_frame()
	session.set_transport_for_tests(transport)
	session.setup_offline_session_for_tests(100)

	var listener := Node3D.new()
	var speaker := Node3D.new()
	auto_free(listener)
	auto_free(speaker)
	add_child(listener)
	add_child(speaker)
	channel.register_listener(listener)
	channel.register_speaker(200, speaker)

	var wire_packet := PackedByteArray([1, 5, 6, 7])
	transport.queue_packet(1, 200, wire_packet)
	var received: Array[int] = [0]
	session.pcm_frame_decompressed.connect(
		func(samples: PackedFloat32Array, _rate: int, _name: String) -> void:
			received[0] = samples.size()
	)
	session.run_frame_for_tests()

	assert_int(received[0]).is_greater(0)
	assert_object(channel.get_speaker_handle(200)).is_not_null()


func test_set_session_peers_used_for_send() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var transport := FakeSteamVoiceTransport.new()
	var session := VoiceSession.new()
	auto_free(session)
	var channel := VoiceChannel.new()
	session.add_child(channel)
	add_child(session)
	await await_idle_frame()
	session.set_transport_for_tests(transport)
	session.setup_offline_session_for_tests(100)
	session.set_session_peers([200, 300])
	transport.set_voice(PackedByteArray([1]))
	session.run_frame_for_tests()
	assert_int(transport.sent_packets.size()).is_equal(2)
	var recipients: Array[int] = []
	for packet in transport.sent_packets:
		recipients.append(int(packet["steam_id"]))
	assert_bool(recipients.has(200)).is_true()
	assert_bool(recipients.has(300)).is_true()


func test_send_pipeline_ptt_blocks_send() -> void:
	var channel: VoiceChannel = auto_free(VoiceChannel.new())
	var input_mod := VoiceInputModifier.new()
	input_mod.input_mode = VoiceInputModifier.InputMode.PUSH_TO_TALK
	channel.modifiers = [input_mod]
	var ctx := VoiceSendContext.new()
	ctx.compressed_voice = PackedByteArray([1, 2, 3])
	ctx.local_steam_id = 100
	ctx.recipients = [100, 200]
	assert_bool(channel.evaluate_send(ctx)).is_false()


func test_send_pipeline_open_mic_allows_roster_member() -> void:
	var channel: VoiceChannel = auto_free(VoiceChannel.new())
	var roster := RosterModifier.new()
	roster.membership = [100, 200]
	var input_mod := VoiceInputModifier.new()
	input_mod.input_mode = VoiceInputModifier.InputMode.OPEN_MIC
	channel.modifiers = [input_mod, roster]
	var ctx := VoiceSendContext.new()
	ctx.compressed_voice = PackedByteArray([1, 2, 3])
	ctx.local_steam_id = 100
	ctx.recipients = [100, 200, 300]
	assert_bool(channel.evaluate_send(ctx)).is_true()
	assert_bool(ctx.recipients.has(300)).is_false()


func test_send_pipeline_roster_blocks_non_member() -> void:
	var channel: VoiceChannel = auto_free(VoiceChannel.new())
	var roster := RosterModifier.new()
	roster.membership = [100, 200]
	channel.modifiers = [roster]
	var ctx := VoiceSendContext.new()
	ctx.compressed_voice = PackedByteArray([1, 2, 3])
	ctx.local_steam_id = 999
	ctx.recipients = [100, 200, 300]
	assert_bool(channel.evaluate_send(ctx)).is_false()
