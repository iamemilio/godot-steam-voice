# GdUnit4 suite: voice session, single-lane transport, and packet pipeline.
extends GdUnitTestSuite


func test_channel_auto_allocation_shared_p2p_port() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var session := VoiceSession.new()
	auto_free(session)
	var voice := VoiceChannel.new()
	voice.channel_name = "Voice"
	session.add_child(voice)
	add_child(session)
	await await_idle_frame()

	VoiceSessionTestSupport.activate_offline(session)
	assert_int(voice.wire_id).is_equal(1)
	assert_int(voice.p2p_port).is_equal(VoicePacket.VOICE_P2P_PORT)


func test_get_channel_by_name() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var session := VoiceSession.new()
	auto_free(session)
	var voice := VoiceChannel.new()
	voice.channel_name = "Voice"
	session.add_child(voice)
	add_child(session)
	await await_idle_frame()
	VoiceSessionTestSupport.activate_offline(session)
	assert_object(session.get_channel("Voice")).is_same(voice)


func test_default_single_channel_one_send_per_peer() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var transport := FakeSteamVoiceTransport.new()
	var session := VoiceSession.new()
	auto_free(session)
	var voice := VoiceChannel.new()
	session.add_child(voice)
	add_child(session)
	await await_idle_frame()
	VoiceSessionTestSupport.set_transport(session, transport)
	VoiceSessionTestSupport.activate_offline(session, 100)
	session.set_session_peers([200, 300])
	transport.set_voice(PackedByteArray([1, 2, 3]))
	VoiceSessionTestSupport.run_frame(session)
	assert_int(transport.sent_packets.size()).is_equal(2)
	for packet in transport.sent_packets:
		assert_int(packet["p2p_port"]).is_equal(VoicePacket.VOICE_P2P_PORT)


func test_separate_comms_allows_multiple_channel_sends() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var transport := FakeSteamVoiceTransport.new()
	var session := VoiceSession.new()
	session.allow_separate_comms = true
	auto_free(session)
	var first := VoiceChannel.new()
	var second := VoiceChannel.new()
	session.add_child(first)
	session.add_child(second)
	add_child(session)
	await await_idle_frame()
	VoiceSessionTestSupport.set_transport(session, transport)
	VoiceSessionTestSupport.activate_offline(session, 100)
	session.set_session_peers([200])
	transport.set_voice(PackedByteArray([1, 2, 3]))
	VoiceSessionTestSupport.run_frame(session)
	assert_int(transport.sent_packets.size()).is_equal(2)


func test_send_packet_includes_wire_id_and_flags() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var transport := FakeSteamVoiceTransport.new()
	var session := VoiceSession.new()
	auto_free(session)
	var channel := VoiceChannel.new()
	session.add_child(channel)
	add_child(session)
	await await_idle_frame()
	VoiceSessionTestSupport.set_transport(session, transport)
	VoiceSessionTestSupport.activate_offline(session, 100)
	session.set_session_peers([200])
	transport.set_voice(PackedByteArray([9, 8, 7]))
	VoiceSessionTestSupport.run_frame(session)
	assert_int(transport.sent_packets.size()).is_equal(1)
	var packet: PackedByteArray = transport.sent_packets[0]["data"]
	assert_int(packet[0]).is_equal(1)
	assert_int(packet[1]).is_equal(0)
	assert_int(packet[2]).is_equal(9)
	assert_int(packet[3]).is_equal(8)
	assert_int(packet[4]).is_equal(7)


func test_receive_pushes_pcm_to_speaker_handle() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var transport := FakeSteamVoiceTransport.new()
	var session := VoiceSession.new()
	auto_free(session)
	var channel := VoiceChannel.new()
	session.add_child(channel)
	add_child(session)
	await await_idle_frame()
	VoiceSessionTestSupport.set_transport(session, transport)
	VoiceSessionTestSupport.activate_offline(session, 100)

	var listener := Node3D.new()
	var speaker := Node3D.new()
	auto_free(listener)
	auto_free(speaker)
	add_child(listener)
	add_child(speaker)
	channel.register_listener(listener)
	channel.register_speaker(200, speaker)

	var wire_packet := VoicePacket.build(1, 0, PackedByteArray([5, 6, 7]))
	transport.queue_packet(VoicePacket.VOICE_P2P_PORT, 200, wire_packet)
	var received: Array[int] = [0]
	session.pcm_frame_decompressed.connect(
		func(samples: PackedFloat32Array, _rate: int, _name: String) -> void:
			received[0] = samples.size()
	)
	VoiceSessionTestSupport.run_frame(session)

	assert_int(received[0]).is_greater(0)
	assert_object(channel.get_speaker_handle(200)).is_not_null()
	assert_int(transport.decompress_count).is_equal(1)


func test_decompress_cache_dedupes_identical_payload_same_frame() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var transport := FakeSteamVoiceTransport.new()
	var session := VoiceSession.new()
	session.allow_separate_comms = true
	auto_free(session)
	var first := VoiceChannel.new()
	var second := VoiceChannel.new()
	session.add_child(first)
	session.add_child(second)
	add_child(session)
	await await_idle_frame()
	VoiceSessionTestSupport.set_transport(session, transport)
	VoiceSessionTestSupport.activate_offline(session, 100)
	var listener := Node3D.new()
	auto_free(listener)
	add_child(listener)
	first.register_listener(listener)
	second.register_listener(listener)
	first.register_speaker(200, listener)
	second.register_speaker(200, listener)
	var payload := PackedByteArray([1, 2, 3])
	transport.queue_packet(
		VoicePacket.VOICE_P2P_PORT, 200, VoicePacket.build(1, 0, payload)
	)
	transport.queue_packet(
		VoicePacket.VOICE_P2P_PORT, 200, VoicePacket.build(2, 0, payload)
	)
	VoiceSessionTestSupport.run_frame(session)
	assert_int(transport.decompress_count).is_equal(1)


func test_proximity_walkie_preset_single_send() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var transport := FakeSteamVoiceTransport.new()
	var session := VoiceSession.new()
	auto_free(session)
	var channel := VoiceChannel.new()
	channel.preset = VoiceChannel.Preset.PROXIMITY
	channel.use_walkie = true
	session.add_child(channel)
	add_child(session)
	await await_idle_frame()
	VoiceSessionTestSupport.set_transport(session, transport)
	VoiceSessionTestSupport.activate_offline(session, 100)
	session.set_session_peers([200])
	transport.set_voice(PackedByteArray([4, 5]))
	VoiceSessionTestSupport.run_frame(session)
	assert_int(transport.sent_packets.size()).is_equal(1)


func test_send_pipeline_ptt_blocks_send() -> void:
	var channel: VoiceChannel = auto_free(VoiceChannel.new())
	channel.preset = VoiceChannel.Preset.CUSTOM
	var input_mod := MicMode.new()
	input_mod.input_mode = MicMode.InputMode.PUSH_TO_TALK
	input_mod.open_mic_enabled = false
	channel.rules = [input_mod]
	var ctx := VoiceSendContext.new()
	ctx.compressed_voice = PackedByteArray([1, 2, 3])
	ctx.local_steam_id = 100
	ctx.recipients = [100, 200]
	assert_bool(channel.evaluate_send(ctx)).is_false()


func test_send_pipeline_open_mic_allows_channel_member() -> void:
	var channel: VoiceChannel = auto_free(VoiceChannel.new())
	channel.preset = VoiceChannel.Preset.CUSTOM
	var roster := ChannelMembers.new()
	roster.membership = [100, 200]
	var input_mod := MicMode.new()
	input_mod.open_mic_enabled = true
	channel.rules = [input_mod, roster]
	var ctx := VoiceSendContext.new()
	ctx.compressed_voice = PackedByteArray([1, 2, 3])
	ctx.local_steam_id = 100
	ctx.recipients = [100, 200, 300]
	assert_bool(channel.evaluate_send(ctx)).is_true()
	assert_bool(ctx.recipients.has(300)).is_false()


func test_send_pipeline_channel_members_blocks_non_member() -> void:
	var channel: VoiceChannel = auto_free(VoiceChannel.new())
	channel.preset = VoiceChannel.Preset.CUSTOM
	var roster := ChannelMembers.new()
	roster.membership = [100, 200]
	channel.rules = [roster]
	var ctx := VoiceSendContext.new()
	ctx.compressed_voice = PackedByteArray([1, 2, 3])
	ctx.local_steam_id = 999
	ctx.recipients = [100, 200, 300]
	assert_bool(channel.evaluate_send(ctx)).is_false()
