# GdUnit4 suite: golden WAV fixtures and playback pipeline replay.
extends GdUnitTestSuite

const FIXTURE_WAV := "res://tests/fixtures/audio/test_audio_sample_01.wav"
const GOLDEN_SLICE_SAMPLES := 4800
const ENERGY_CHECK_START := 240000
const PIPELINE_SLICE_SAMPLES := 4096


func _fixture() -> Dictionary:
	return VoiceFixtureLoader.load_mono_pcm(FIXTURE_WAV)


func _make_handle(steam_id: int = 42) -> VoiceSpeakerHandle:
	var parent := Node3D.new()
	auto_free(parent)
	add_child(parent)
	var handle := VoiceSpeakerHandle.new()
	handle.setup(parent, steam_id, parent)
	return handle


func _await_playback(handle: VoiceSpeakerHandle) -> AudioStreamGeneratorPlayback:
	await await_idle_frame()
	var playback := handle.player.get_stream_playback()
	assert_object(playback).is_not_null()
	assert_bool(playback is AudioStreamGeneratorPlayback).is_true()
	return playback as AudioStreamGeneratorPlayback


func test_fixture_wav_loads_from_disk() -> void:
	var fixture := _fixture()
	assert_dict(fixture).is_not_empty()
	assert_int(fixture["sample_rate"]).is_equal(48000)
	assert_float(fixture["duration_sec"]).is_greater_equal(10.0)


func test_fixture_mono_pcm_matches_manifest_golden() -> void:
	var fixture := _fixture()
	var entry := VoiceFixtureLoader.get_manifest_entry("test_audio_sample_01.wav")
	assert_dict(fixture).is_not_empty()
	assert_int(fixture["sample_rate"]).is_equal(int(entry.get("sample_rate", 0)))
	assert_float(fixture["duration_sec"]).is_greater_equal(float(entry.get("min_duration_sec", 0.0)))

	var golden_md5 := str(entry.get("golden_mono_md5_first_4800", ""))
	assert_str(golden_md5).is_not_empty()
	var actual_md5 := VoiceFixtureLoader.md5_mono_s16_prefix(
		fixture["buffer"], GOLDEN_SLICE_SAMPLES
	)
	assert_str(actual_md5).is_equal(golden_md5)


func test_fixture_slice_has_nonzero_energy() -> void:
	var fixture := _fixture()
	var samples: PackedFloat32Array = fixture["samples"]
	var start := ENERGY_CHECK_START
	assert_int(samples.size()).is_greater(start + GOLDEN_SLICE_SAMPLES)
	var slice := samples.slice(start, start + GOLDEN_SLICE_SAMPLES)
	var sum_sq := 0.0
	for sample in slice:
		sum_sq += sample * sample
	var rms := sqrt(sum_sq / float(slice.size()))
	assert_float(rms).is_greater(0.01)


func test_fixture_replays_through_fake_transport_decompress() -> void:
	var fixture := _fixture()
	var transport := FakeSteamVoiceTransport.new()
	var pcm_buffer: PackedByteArray = fixture["buffer"]
	var sample_rate: int = fixture["sample_rate"]
	transport.set_decompress_result(pcm_buffer, sample_rate)

	var result := transport.decompress_voice(PackedByteArray([1, 2, 3]))
	assert_int(transport.decompress_count).is_equal(1)
	assert_int(result["sample_rate"]).is_equal(sample_rate)
	var out_samples := SteamVoiceTransport.pcm_bytes_to_mono_floats(result["buffer"])
	assert_int(out_samples.size()).is_equal(fixture["samples"].size())


func test_fixture_pcm_pushes_through_speaker_handle() -> void:
	var fixture := _fixture()
	var handle := _make_handle()
	await _await_playback(handle)
	var slice: PackedFloat32Array = fixture["samples"].slice(0, GOLDEN_SLICE_SAMPLES)
	handle.push_pcm(slice, fixture["sample_rate"])
	assert_int(handle.pending_samples.size()).is_equal(GOLDEN_SLICE_SAMPLES)
	assert_int(handle.sample_rate).is_equal(fixture["sample_rate"])
	handle.flush_to_playback()
	assert_int(handle.pending_samples.size()).is_less_equal(GOLDEN_SLICE_SAMPLES)


func test_fixture_receive_pipeline_end_to_end() -> void:
	OS.set_environment("STEAM_PROXIMITY_VOICE_TEST", "1")
	var fixture := _fixture()
	var pcm_slice: PackedByteArray = fixture["buffer"].slice(0, PIPELINE_SLICE_SAMPLES * 2)
	var transport := FakeSteamVoiceTransport.new()
	transport.set_decompress_result(pcm_slice, fixture["sample_rate"])

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

	var compressed := PackedByteArray([0xAA, 0xBB, 0xCC])
	var wire_packet := VoicePacket.build(1, 0, compressed)
	transport.queue_packet(VoicePacket.VOICE_P2P_PORT, 200, wire_packet)

	var received: Array[int] = [0]
	var received_rate: Array[int] = [0]
	session.pcm_frame_decompressed.connect(
		func(samples: PackedFloat32Array, rate: int, _name: String) -> void:
			received[0] = samples.size()
			received_rate[0] = rate
	)
	VoiceSessionTestSupport.run_frame(session)

	assert_int(received[0]).is_equal(PIPELINE_SLICE_SAMPLES)
	assert_int(received_rate[0]).is_equal(fixture["sample_rate"])
	var handle := channel.get_speaker_handle(200)
	assert_object(handle).is_not_null()
	assert_int(handle.sample_rate).is_equal(fixture["sample_rate"])
