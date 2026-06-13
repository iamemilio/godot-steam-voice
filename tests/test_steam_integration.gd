# GdUnit4 suite: Steam transport, PCM conversion, and peer adapter.
extends GdUnitTestSuite


func test_pcm_bytes_to_mono_floats() -> void:
	var buffer := PackedByteArray()
	buffer.resize(4)
	buffer.encode_s16(0, 16384)
	buffer.encode_s16(2, -16384)
	var samples := SteamVoiceTransport.pcm_bytes_to_mono_floats(buffer)
	assert_int(samples.size()).is_equal(2)
	assert_float(samples[0]).is_equal_approx(0.5, 0.001)
	assert_float(samples[1]).is_equal_approx(-0.5, 0.001)


func test_pcm_floats_to_stereo_frames() -> void:
	var samples := PackedFloat32Array([0.25, -0.25])
	var frames := SteamVoiceTransport.pcm_floats_to_stereo_frames(samples)
	assert_int(frames.size()).is_equal(2)
	assert_vector(frames[0]).is_equal(Vector2(0.25, 0.25))
	assert_vector(frames[1]).is_equal(Vector2(-0.25, -0.25))


func test_offline_transport_get_voice_is_empty() -> void:
	var transport := SteamVoiceTransport.new()
	assert_bool(transport.available).is_false()
	assert_int(transport.get_voice().size()).is_equal(0)


func test_offline_transport_send_packet_noops() -> void:
	var transport := SteamVoiceTransport.new()
	transport.send_packet(123, PackedByteArray([1, 2]), 1)


func test_fake_transport_records_sent_packets() -> void:
	var transport := FakeSteamVoiceTransport.new()
	var payload := PackedByteArray([4, 5, 6])
	transport.send_packet(42, payload, 2)
	assert_int(transport.sent_packets.size()).is_equal(1)
	assert_int(transport.sent_packets[0]["steam_id"]).is_equal(42)
	assert_int(transport.sent_packets[0]["p2p_port"]).is_equal(2)


func test_adapter_get_steam_id_for_peer() -> void:
	var peer := StubMultiplayerPeer.new()
	peer.set_steam_id(2, 7654321)
	assert_int(SteamMultiplayerPeerAdapter.get_steam_id_for_peer(peer, 2)).is_equal(7654321)
	assert_int(SteamMultiplayerPeerAdapter.get_steam_id_for_peer(peer, 9)).is_equal(0)


func test_adapter_collects_session_steam_ids() -> void:
	var api := StubMultiplayerAPI.new()
	api.multiplayer_peer = StubMultiplayerPeer.new()
	api.multiplayer_peer.set_steam_id(1, 1000)
	api.multiplayer_peer.set_steam_id(2, 2000)
	api.peer_ids = [2]
	var ids := SteamMultiplayerPeerAdapter.collect_session_steam_ids(api)
	assert_int(ids.size()).is_equal(2)
	assert_bool(ids.has(1000)).is_true()
	assert_bool(ids.has(2000)).is_true()
