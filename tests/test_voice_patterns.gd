# GdUnit4 suite: new API patterns — presets, transmit flags, VoiceMember, single-lane guard.
extends GdUnitTestSuite


func test_voice_packet_build_and_parse() -> void:
	var payload := PackedByteArray([9, 8, 7])
	var raw := VoicePacket.build(2, VoicePacket.FLAG_WALKIE_ACTIVE, payload)
	assert_int(raw.size()).is_equal(5)
	assert_int(raw[0]).is_equal(2)
	assert_int(raw[1]).is_equal(VoicePacket.FLAG_WALKIE_ACTIVE)
	assert_int(raw[2]).is_equal(9)

	var parsed := VoicePacket.parse(raw)
	assert_int(parsed.get("wire_id", -1)).is_equal(2)
	assert_int(parsed.get("flags", -1)).is_equal(VoicePacket.FLAG_WALKIE_ACTIVE)
	assert_object(parsed.get("compressed")).is_equal(payload)


func test_voice_packet_parse_rejects_short_buffer() -> void:
	assert_bool(VoicePacket.parse(PackedByteArray([1, 2])).is_empty()).is_true()


func test_proximity_preset_builds_proximity_volume_rule() -> void:
	var channel: VoiceChannel = auto_free(VoiceChannel.new())
	channel.preset = VoiceChannel.Preset.PROXIMITY
	channel._rebuild_preset_rules()
	var found := false
	for rule in channel.get_effective_rules():
		if rule is ProximityVolume:
			found = true
	assert_bool(found).is_true()


func test_walkie_ptt_sets_transmit_flag() -> void:
	var mic := MicMode.new()
	mic.open_mic_enabled = true
	mic.walkie_ptt_action = "radio_push"
	mic._walkie_ptt_held = true
	var ctx := VoiceSendContext.new()
	mic.apply_transmit_flags(ctx)
	assert_int(ctx.transmit_flags & VoicePacket.FLAG_WALKIE_ACTIVE).is_not_equal(0)


func test_voice_effects_bus_only_when_walkie_flag_set() -> void:
	var bus := VoiceEffectsBus.new()
	bus.bus_name = "VoiceRadio"
	bus.walkie_only = true
	var ctx := VoicePlaybackContext.new()
	bus.configure_playback(ctx, null)
	assert_str(ctx.audio_bus).is_equal("Master")
	ctx.transmit_flags = VoicePacket.FLAG_WALKIE_ACTIVE
	bus.configure_playback(ctx, null)
	assert_str(ctx.audio_bus).is_equal("VoiceRadio")


func test_two_channels_without_opt_in_sends_once_per_peer() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var transport := FakeSteamVoiceTransport.new()
	var session := VoiceSession.new()
	auto_free(session)
	session.add_child(VoiceChannel.new())
	session.add_child(VoiceChannel.new())
	add_child(session)
	await await_idle_frame()
	VoiceSessionTestSupport.set_transport(session, transport)
	VoiceSessionTestSupport.activate_offline(session, 100)
	session.set_session_peers([200])
	transport.set_voice(PackedByteArray([1, 2]))
	VoiceSessionTestSupport.run_frame(session)
	assert_int(transport.sent_packets.size()).is_equal(1)


func test_start_and_stop_lifecycle() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var session := VoiceSession.new()
	auto_free(session)
	session.add_child(VoiceChannel.new())
	add_child(session)
	await await_idle_frame()
	assert_bool(session.is_active).is_false()
	session.start()
	assert_bool(session.is_active).is_true()
	session.stop()
	assert_bool(session.is_active).is_false()


func test_voice_member_registers_local_listener() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var session := VoiceSession.new()
	auto_free(session)
	var channel := VoiceChannel.new()
	session.add_child(channel)
	add_child(session)
	await await_idle_frame()
	VoiceSessionTestSupport.activate_offline(session, 100)

	var player := Node3D.new()
	var head := Node3D.new()
	head.name = "Head"
	player.add_child(head)
	session.add_child(player)

	var member := VoiceMember.new()
	member.steam_id = 100
	player.add_child(member)
	await await_idle_frame()

	assert_object(channel.get_listener_node()).is_same(head)
