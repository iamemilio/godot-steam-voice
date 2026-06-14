class_name VoiceSpeakerHandle
extends RefCounted

## Playback state for one remote speaker on one voice channel.

const RING_CAPACITY := 48000

var steam_id: int = 0
var speaker_node: Node3D
var player: AudioStreamPlayer3D
var sample_rate: int = SteamVoiceTransport.DEFAULT_SAMPLE_RATE
var pending_samples: PackedFloat32Array = PackedFloat32Array()
var _parent_node: Node3D


func setup(parent: Node3D, remote_steam_id: int, attach_node: Node3D) -> void:
	steam_id = remote_steam_id
	speaker_node = attach_node
	_parent_node = parent
	if player == null:
		player = AudioStreamPlayer3D.new()
		player.name = "VoiceSpeaker_%d" % remote_steam_id
		var stream := AudioStreamGenerator.new()
		stream.mix_rate = float(sample_rate)
		stream.buffer_length = 0.1
		player.stream = stream
		player.unit_size = 1.0
		player.max_distance = 100.0
		player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
	_parent_node.add_child(player)
	if attach_node != null and is_instance_valid(attach_node):
		player.reparent(attach_node)
		player.position = Vector3.ZERO
	if not player.playing:
		player.play()


func push_pcm(samples: PackedFloat32Array, new_sample_rate: int) -> void:
	if samples.is_empty():
		return
	if new_sample_rate > 0 and new_sample_rate != sample_rate:
		sample_rate = new_sample_rate
		if player != null and player.stream is AudioStreamGenerator:
			(player.stream as AudioStreamGenerator).mix_rate = float(sample_rate)
	var combined := pending_samples
	combined.append_array(samples)
	pending_samples = combined
	if pending_samples.size() > RING_CAPACITY:
		pending_samples = pending_samples.slice(pending_samples.size() - RING_CAPACITY)


func flush_to_playback() -> void:
	if player == null or not player.playing:
		return
	var playback := player.get_stream_playback()
	if playback == null or not playback is AudioStreamGeneratorPlayback:
		return
	var gen := playback as AudioStreamGeneratorPlayback
	var available := gen.get_frames_available()
	if available <= 0 or pending_samples.is_empty():
		return
	var to_push := mini(available, pending_samples.size())
	var frames := SteamVoiceTransport.pcm_floats_to_stereo_frames(pending_samples.slice(0, to_push))
	gen.push_buffer(frames)
	if to_push >= pending_samples.size():
		pending_samples = PackedFloat32Array()
	else:
		pending_samples = pending_samples.slice(to_push)


func apply_volume_db(volume_db: float, bus_name: String) -> void:
	if player == null:
		return
	player.volume_db = volume_db
	if not bus_name.is_empty():
		player.bus = bus_name


func cleanup() -> void:
	if player != null and is_instance_valid(player):
		player.stop()
		player.queue_free()
	player = null
	speaker_node = null
	pending_samples = PackedFloat32Array()
