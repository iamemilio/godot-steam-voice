# GdUnit4 suite: VoiceSpeakerHandle PCM buffering and AudioStreamGenerator playback.
extends GdUnitTestSuite


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


func _sine_samples(count: int, amplitude: float = 0.5) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		samples[i] = amplitude * sin(float(i) * TAU / 48.0)
	return samples


func test_push_pcm_accumulates_pending_samples() -> void:
	var handle := _make_handle()
	var samples := _sine_samples(128)
	handle.push_pcm(samples, SteamVoiceTransport.DEFAULT_SAMPLE_RATE)
	assert_int(handle.pending_samples.size()).is_equal(128)


func test_push_pcm_empty_is_noop() -> void:
	var handle := _make_handle()
	handle.push_pcm(PackedFloat32Array(), SteamVoiceTransport.DEFAULT_SAMPLE_RATE)
	assert_int(handle.pending_samples.size()).is_equal(0)


func test_flush_to_playback_drains_pending_samples() -> void:
	var handle := _make_handle()
	await _await_playback(handle)
	handle.push_pcm(_sine_samples(256), SteamVoiceTransport.DEFAULT_SAMPLE_RATE)
	handle.flush_to_playback()
	assert_int(handle.pending_samples.size()).is_equal(0)


func test_flush_to_playback_pushes_frames_into_generator() -> void:
	var handle := _make_handle()
	var playback := await _await_playback(handle)
	var space_before := playback.get_frames_available()
	assert_int(space_before).is_greater(0)

	handle.push_pcm(_sine_samples(512), SteamVoiceTransport.DEFAULT_SAMPLE_RATE)
	handle.flush_to_playback()

	assert_int(handle.pending_samples.size()).is_equal(0)
	assert_int(playback.get_frames_available()).is_less(space_before)


func test_flush_leaves_remainder_when_generator_space_is_limited() -> void:
	var handle := _make_handle()
	var playback := await _await_playback(handle)
	var space := playback.get_frames_available()
	assert_int(space).is_greater(0)

	var sample_count := space + 64
	handle.push_pcm(_sine_samples(sample_count), SteamVoiceTransport.DEFAULT_SAMPLE_RATE)
	handle.flush_to_playback()

	assert_int(handle.pending_samples.size()).is_equal(64)
	assert_int(playback.get_frames_available()).is_equal(0)


func test_flush_without_playing_keeps_pending_samples() -> void:
	var handle := _make_handle()
	await _await_playback(handle)
	handle.push_pcm(_sine_samples(64), SteamVoiceTransport.DEFAULT_SAMPLE_RATE)
	handle.player.stop()
	handle.flush_to_playback()
	assert_int(handle.pending_samples.size()).is_equal(64)


func test_push_pcm_updates_generator_mix_rate() -> void:
	var handle := _make_handle()
	await _await_playback(handle)
	var new_rate := 48000
	handle.push_pcm(_sine_samples(32), new_rate)
	assert_int(handle.sample_rate).is_equal(new_rate)
	var stream := handle.player.stream as AudioStreamGenerator
	assert_float(stream.mix_rate).is_equal(float(new_rate))


func test_push_pcm_ring_capacity_truncates_oldest_samples() -> void:
	var handle := _make_handle()
	var overflow := VoiceSpeakerHandle.RING_CAPACITY + 100
	var samples := PackedFloat32Array()
	samples.resize(overflow)
	for i in overflow:
		samples[i] = float(i)
	handle.push_pcm(samples, SteamVoiceTransport.DEFAULT_SAMPLE_RATE)
	assert_int(handle.pending_samples.size()).is_equal(VoiceSpeakerHandle.RING_CAPACITY)
	assert_float(handle.pending_samples[0]).is_equal(float(100))
