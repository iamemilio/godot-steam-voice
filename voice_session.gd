class_name VoiceSession
extends Node

## Root voice node. Add VoiceChannel children, call begin_session(), register participants once.

signal session_started()
signal session_ended()
signal channel_registered(channel: VoiceChannel)
signal pcm_frame_decompressed(samples: PackedFloat32Array, sample_rate: int, channel_name: String)

@export var enabled: bool = true
@export var room_graph: RoomGraph

var is_active: bool = false
var local_steam_id: int = 0

var _transport
var _channels: Array[VoiceChannel] = []
var _channels_by_wire_id: Dictionary = {}
var _channels_by_name: Dictionary = {}
var _session_peers: Array[int] = []
var _next_wire_id: int = 1
var _next_p2p_port: int = 1
var _test_mode: bool = false


func _ready() -> void:
	_transport = SteamVoiceTransport.new()
	_test_mode = _detect_test_mode()
	if _test_mode:
		set_process(false)


func _detect_test_mode() -> bool:
	return (
		OS.get_environment("STEAM_PROXIMITY_VOICE_TEST") == "1"
	)


func _process(delta: float) -> void:
	if not is_active or not enabled or _test_mode:
		return
	_tick_frame(delta)


func begin_session() -> void:
	if is_active:
		return
	if _test_mode or not _transport.available:
		return
	_discover_channels()
	if _channels.is_empty():
		return
	_allocate_channel_ids()
	local_steam_id = _resolve_local_steam_id()
	_transport.start_recording()
	is_active = true
	set_process(true)
	for channel in _channels:
		channel.notify_registered()
		channel_registered.emit(channel)
	session_started.emit()


func end_session() -> void:
	if not is_active:
		return
	_transport.stop_recording()
	for channel in _channels:
		channel.notify_unregistered()
	is_active = false
	set_process(false)
	_channels.clear()
	_channels_by_wire_id.clear()
	_channels_by_name.clear()
	_next_wire_id = 1
	_next_p2p_port = 1
	session_ended.emit()


func get_channel(name: String) -> VoiceChannel:
	return _channels_by_name.get(name) as VoiceChannel


func get_channels() -> Array[VoiceChannel]:
	return _channels.duplicate()


func set_session_peers(steam_ids: Array[int]) -> void:
	_session_peers = steam_ids.duplicate()


func get_session_peers() -> Array[int]:
	if not _session_peers.is_empty():
		return _session_peers.duplicate()
	return _discover_peers_from_steam()


func setup_offline_session_for_tests(local_id: int = 100) -> void:
	if not _test_mode:
		return
	_discover_channels()
	if _channels.is_empty():
		return
	_allocate_channel_ids()
	local_steam_id = local_id
	is_active = true


func set_transport_for_tests(transport: RefCounted) -> void:
	if not _test_mode:
		return
	_transport = transport


func run_frame_for_tests(delta: float = 0.0) -> void:
	if not _test_mode or not is_active:
		return
	_tick_frame(delta)


func _discover_channels() -> void:
	_channels.clear()
	_channels_by_wire_id.clear()
	_channels_by_name.clear()
	for child in get_children():
		if child is VoiceChannel:
			var channel := child as VoiceChannel
			channel.bind_session(self)
			_channels.append(channel)
			if not channel.channel_name.is_empty():
				_channels_by_name[channel.channel_name] = channel


func _allocate_channel_ids() -> void:
	_next_wire_id = 1
	_next_p2p_port = 1
	for channel in _channels:
		channel.wire_id = _next_wire_id
		channel.p2p_port = _next_p2p_port
		_channels_by_wire_id[_next_wire_id] = channel
		_next_wire_id += 1
		_next_p2p_port += 1


func _tick_frame(delta: float) -> void:
	for channel in _channels:
		channel.process_modifiers_frame(delta)
	var compressed: PackedByteArray = _transport.get_voice()
	_send_voice(compressed)
	_receive_voice()
	_update_playback()


func _send_voice(compressed: PackedByteArray) -> void:
	if compressed.is_empty():
		return
	var peers := get_session_peers()
	var base_ctx := VoiceSendContext.new()
	base_ctx.session = self
	base_ctx.compressed_voice = compressed
	base_ctx.local_steam_id = local_steam_id
	base_ctx.all_steam_ids = peers
	for channel in _channels:
		if not channel.enabled or channel.wire_id < 0:
			continue
		var ctx := base_ctx.duplicate_for_channel()
		ctx.channel = channel
		if not channel.evaluate_send(ctx):
			continue
		var packet := PackedByteArray()
		packet.append(channel.wire_id & 0xFF)
		packet.append_array(compressed)
		for recipient in ctx.recipients:
			var steam_id := int(recipient)
			if steam_id == local_steam_id:
				continue
			_transport.send_packet(steam_id, packet, channel.p2p_port)


func _receive_voice() -> void:
	for channel in _channels:
		if channel.p2p_port < 0:
			continue
		var packets: Array[Dictionary] = _transport.read_packets(channel.p2p_port)
		for packet_data in packets:
			_process_incoming_packet(channel, packet_data)


func _process_incoming_packet(default_channel: VoiceChannel, packet_data: Dictionary) -> void:
	var raw: PackedByteArray = packet_data.get("data", PackedByteArray()) as PackedByteArray
	var sender_steam_id := int(packet_data.get("steam_id", 0))
	if raw.is_empty() or sender_steam_id == 0:
		return
	if raw.size() < 2:
		return
	var wire_id := int(raw[0])
	var compressed_payload: PackedByteArray = raw.slice(1)
	var channel: VoiceChannel = _channels_by_wire_id.get(wire_id, default_channel) as VoiceChannel
	if channel == null:
		return
	var decompressed: Dictionary = _transport.decompress_voice(compressed_payload)
	if decompressed.is_empty():
		return
	var pcm_buffer: PackedByteArray = decompressed.get("buffer", PackedByteArray()) as PackedByteArray
	var sample_rate := int(decompressed.get("sample_rate", SteamVoiceTransport.DEFAULT_SAMPLE_RATE))
	var samples := SteamVoiceTransport.pcm_bytes_to_mono_floats(pcm_buffer)
	if samples.is_empty():
		return
	pcm_frame_decompressed.emit(samples, sample_rate, channel.channel_name)
	var handle := channel.get_or_create_handle(sender_steam_id)
	handle.push_pcm(samples, sample_rate)


func _update_playback() -> void:
	for channel in _channels:
		if channel.enabled:
			channel.update_playback()


func _resolve_local_steam_id() -> int:
	if Engine.has_singleton("Steam"):
		var steam: Object = Engine.get_singleton("Steam")
		if steam.has_method("getSteamID"):
			return int(steam.call("getSteamID"))
	return 0


func _discover_peers_from_steam() -> Array[int]:
	var peers: Array[int] = []
	var tree := get_tree()
	if tree == null:
		return peers
	var mp := tree.get_multiplayer()
	if mp == null:
		return peers
	var peer := mp.multiplayer_peer
	if peer == null:
		return peers
	if peer.has_method("get_steam_id_for_peer_id"):
		for peer_id in mp.get_peers():
			var steam_id := int(peer.call("get_steam_id_for_peer_id", peer_id))
			if steam_id != 0:
				peers.append(steam_id)
		var host_id := int(peer.call("get_steam_id_for_peer_id", 1))
		if host_id != 0 and not peers.has(host_id):
			peers.append(host_id)
	return peers
