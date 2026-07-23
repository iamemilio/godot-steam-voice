class_name VoiceSession
extends Node

## Root voice node. One channel by default; one send and one decompress per packet.

signal session_started()
signal session_ended()
signal channel_registered(channel: VoiceChannel)
signal pcm_frame_decompressed(samples: PackedFloat32Array, sample_rate: int, channel_name: String)
signal voice_debug(event: String, detail: String)

@export var enabled: bool = true
@export var auto_start: bool = false
@export var allow_separate_comms: bool = false
@export var debug_logging: bool = false
@export var muffling_map: MufflingMap

var is_active: bool = false
var local_steam_id: int = 0

var _transport
var _channels: Array[VoiceChannel] = []
var _channels_by_wire_id: Dictionary = {}
var _channels_by_name: Dictionary = {}
var _session_peers: Array[int] = []
var _next_wire_id: int = 1
var _members: Dictionary = {}
var _decompress_cache: Dictionary = {}
var _separate_comms_warned: bool = false
var _test_mode: bool = false
var _unbound_speaker_warned: Dictionary = {}


func _ready() -> void:
	add_to_group("voice_session")
	_transport = SteamVoiceTransport.new()
	_test_mode = _detect_test_mode()
	if _test_mode:
		set_process(false)
	elif auto_start:
		call_deferred("_try_auto_start")


func _detect_test_mode() -> bool:
	return OS.get_environment("STEAM_PROXIMITY_VOICE_TEST") == "1"


func _try_auto_start() -> void:
	if get_session_peers().is_empty():
		return
	start()


func _process(delta: float) -> void:
	if not is_active or not enabled or _test_mode:
		return
	_tick_frame(delta)


func start() -> void:
	if is_active:
		return
	if _test_mode:
		_start_internal()
		return
	if not _transport.available:
		return
	_start_internal()


func _start_internal() -> void:
	_discover_channels()
	if _channels.is_empty():
		return
	_warn_if_multiple_channels_without_opt_in()
	_allocate_channel_ids()
	local_steam_id = _resolve_local_steam_id()
	if not _test_mode:
		_transport.start_recording()
	is_active = true
	set_process(true)
	for channel in _channels:
		channel.notify_registered()
		channel_registered.emit(channel)
	_register_pending_members()
	session_started.emit()


func stop() -> void:
	if not is_active:
		return
	if not _test_mode:
		_transport.stop_recording()
	for channel in _channels:
		channel.notify_unregistered()
	# Keep _members so start() can re-bind heads; only tear down channel wiring.
	is_active = false
	set_process(false)
	_channels.clear()
	_channels_by_wire_id.clear()
	_channels_by_name.clear()
	_next_wire_id = 1
	_decompress_cache.clear()
	_unbound_speaker_warned.clear()
	session_ended.emit()


func get_channel(name: String) -> VoiceChannel:
	return _channels_by_name.get(name) as VoiceChannel


func get_channels() -> Array[VoiceChannel]:
	return _channels.duplicate()


func get_primary_channel() -> VoiceChannel:
	if _channels.is_empty():
		return null
	return _channels[0] as VoiceChannel


func set_session_peers(steam_ids: Array[int]) -> void:
	_session_peers = _filter_valid_steam_ids(steam_ids)


func refresh_member_bindings() -> void:
	if not is_active:
		return
	var channel := get_primary_channel()
	if channel != null:
		# Drop stale listener/speaker maps before rebinding (authority / Steam ID can change).
		channel.clear_speakers()
		channel.register_listener(null)
	for member in _members.keys():
		var voice_member := member as VoiceMember
		if voice_member == null:
			continue
		var data: Dictionary = _members[member]
		# Re-resolve every refresh — peer→Steam maps and authority can arrive late.
		var steam_id := voice_member.resolve_steam_id()
		var is_local := voice_member.is_local_member()
		data["steam_id"] = steam_id
		data["is_local"] = is_local
		var head := data.get("head") as Node3D
		if head == null or not is_instance_valid(head):
			head = voice_member.get_head_node()
			data["head"] = head
		_apply_member_binding(steam_id, head, is_local)


func get_session_peers() -> Array[int]:
	return _merge_steam_ids(_session_peers, _discover_peers_from_steam())


func bind_member(member_steam_id: int, head: Node3D, is_local: bool, member: VoiceMember) -> void:
	if head == null:
		return
	_members[member] = {"steam_id": member_steam_id, "head": head, "is_local": is_local}
	if not is_active:
		return
	_apply_member_binding(member_steam_id, head, is_local)


func unbind_member(member: VoiceMember) -> void:
	if not _members.has(member):
		return
	var data: Dictionary = _members[member]
	var member_steam_id := int(data.get("steam_id", 0))
	var channel := get_primary_channel()
	if channel != null:
		if data.get("is_local", false):
			channel.register_listener(null)
		elif member_steam_id != 0:
			channel.unregister_speaker(member_steam_id)
	_members.erase(member)


func _register_pending_members() -> void:
	# Same path as refresh — never trust sticky steam_id / is_local from first bind.
	refresh_member_bindings()


func find_head_for_steam_id(steam_id: int) -> Node3D:
	if steam_id == 0:
		return null
	for member in _members.keys():
		var voice_member := member as VoiceMember
		if voice_member == null:
			continue
		var data: Dictionary = _members[member]
		var member_id := int(data.get("steam_id", 0))
		if member_id == 0:
			member_id = voice_member.resolve_steam_id()
			data["steam_id"] = member_id
		if member_id != steam_id:
			continue
		if bool(data.get("is_local", false)):
			continue
		var head := data.get("head") as Node3D
		if head != null and is_instance_valid(head):
			return head
		return voice_member.get_head_node()
	return null


func _merge_steam_ids(primary: Array[int], secondary: Array[int]) -> Array[int]:
	var merged: Array[int] = []
	var seen: Dictionary = {}
	for source in [primary, secondary]:
		for steam_id in source:
			var id := int(steam_id)
			if id == 0 or seen.has(id):
				continue
			seen[id] = true
			merged.append(id)
	return merged


func _filter_valid_steam_ids(steam_ids: Array[int]) -> Array[int]:
	return _merge_steam_ids(steam_ids, [])


func _apply_member_binding(member_steam_id: int, head: Node3D, is_local: bool) -> void:
	var channel := get_primary_channel()
	if channel == null:
		return
	if is_local:
		channel.register_listener(head)
	elif member_steam_id != 0:
		channel.register_speaker(member_steam_id, head)


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


func _warn_if_multiple_channels_without_opt_in() -> void:
	if allow_separate_comms or _channels.size() <= 1 or _separate_comms_warned:
		return
	_separate_comms_warned = true
	push_warning(
		"VoiceSession: multiple VoiceChannel nodes duplicate voice traffic. "
		+ "Use one channel with proximity + walkie presets, or set allow_separate_comms."
	)


func _allocate_channel_ids() -> void:
	_next_wire_id = 1
	for channel in _channels:
		channel.wire_id = _next_wire_id
		channel.p2p_port = VoicePacket.VOICE_P2P_PORT
		_channels_by_wire_id[_next_wire_id] = channel
		_next_wire_id += 1


func _tick_frame(delta: float) -> void:
	_decompress_cache.clear()
	for channel in _channels:
		channel.process_rules_frame(delta)
	var compressed: PackedByteArray = _transport.get_voice()
	_send_voice(compressed)
	_receive_voice()
	_update_playback()


func _send_voice(compressed: PackedByteArray) -> void:
	if compressed.is_empty():
		return
	var peers := get_session_peers()
	if peers.is_empty():
		_emit_debug("empty_peers", "getVoice had data but session peer list is empty")
		return
	var base_ctx := VoiceSendContext.new()
	base_ctx.session = self
	base_ctx.compressed_voice = compressed
	base_ctx.local_steam_id = local_steam_id
	base_ctx.all_steam_ids = peers

	if allow_separate_comms:
		for channel in _channels:
			_send_for_channel(channel, base_ctx)
	else:
		var channel := get_primary_channel()
		if channel != null:
			_send_for_channel(channel, base_ctx)


func _send_for_channel(channel: VoiceChannel, base_ctx: VoiceSendContext) -> void:
	if not channel.enabled or channel.wire_id < 0:
		return
	var ctx := base_ctx.duplicate_for_channel()
	ctx.channel = channel
	if not channel.evaluate_send(ctx):
		return
	var packet := VoicePacket.build(channel.wire_id, ctx.transmit_flags, ctx.compressed_voice)
	var sent_to: Array[int] = []
	for recipient in ctx.recipients:
		var steam_id := int(recipient)
		if steam_id == local_steam_id:
			continue
		_transport.send_packet(steam_id, packet, VoicePacket.VOICE_P2P_PORT)
		sent_to.append(steam_id)
	if sent_to.is_empty():
		_emit_debug("send_no_targets", "recipients after local filter were empty")
		return
	_emit_debug("send_frame", "bytes=%d to=%s" % [packet.size(), sent_to])


func _receive_voice() -> void:
	var packets: Array[Dictionary] = _transport.read_packets(VoicePacket.VOICE_P2P_PORT)
	for packet_data in packets:
		_process_incoming_packet(packet_data)


func _process_incoming_packet(packet_data: Dictionary) -> void:
	var raw: PackedByteArray = packet_data.get("data", PackedByteArray()) as PackedByteArray
	var sender_steam_id := SteamVoiceTransport.parse_sender_steam_id(packet_data)
	if raw.is_empty() or sender_steam_id == 0:
		return
	var parsed := VoicePacket.parse(raw)
	if parsed.is_empty():
		return
	var wire_id := int(parsed.get("wire_id", 0))
	var flags := int(parsed.get("flags", 0))
	var compressed_payload: PackedByteArray = (
		parsed.get("compressed", PackedByteArray()) as PackedByteArray
	)
	var channel: VoiceChannel = (
		_channels_by_wire_id.get(wire_id, get_primary_channel()) as VoiceChannel
	)
	if channel == null:
		return

	var cache_key := VoicePacket.payload_cache_key(sender_steam_id, compressed_payload)
	var samples: PackedFloat32Array
	var sample_rate: int = SteamVoiceTransport.DEFAULT_SAMPLE_RATE
	if _decompress_cache.has(cache_key):
		var cached: Dictionary = _decompress_cache[cache_key]
		samples = cached.get("samples", PackedFloat32Array()) as PackedFloat32Array
		sample_rate = int(cached.get("sample_rate", sample_rate))
	else:
		var decompressed: Dictionary = _transport.decompress_voice(compressed_payload)
		if decompressed.is_empty():
			return
		var pcm_buffer: PackedByteArray = decompressed.get("buffer", PackedByteArray()) as PackedByteArray
		sample_rate = int(decompressed.get("sample_rate", SteamVoiceTransport.DEFAULT_SAMPLE_RATE))
		samples = SteamVoiceTransport.pcm_bytes_to_mono_floats(pcm_buffer)
		if samples.is_empty():
			return
		_decompress_cache[cache_key] = {"samples": samples, "sample_rate": sample_rate}

	channel.set_speaker_transmit_flags(sender_steam_id, flags)
	pcm_frame_decompressed.emit(samples, sample_rate, channel.channel_name)
	# Late peer→Steam maps: bind speaker from member heads before creating playback.
	if channel.get_speaker_node(sender_steam_id) == null:
		var head := find_head_for_steam_id(sender_steam_id)
		if head != null:
			channel.register_speaker(sender_steam_id, head)
			_emit_debug("speaker_late_bind", "steam_id=%s" % sender_steam_id)
		else:
			if not _unbound_speaker_warned.has(sender_steam_id):
				_unbound_speaker_warned[sender_steam_id] = true
				_emit_debug(
					"recv_unbound_speaker",
					"steam_id=%s samples=%d" % [sender_steam_id, samples.size()]
				)
	var handle := channel.get_or_create_handle(sender_steam_id)
	handle.push_pcm(samples, sample_rate)
	_emit_debug(
		"recv_packet",
		"from=%s samples=%d rate=%d" % [sender_steam_id, samples.size(), sample_rate]
	)


func _update_playback() -> void:
	for channel in _channels:
		if channel.enabled:
			channel.update_playback()


func _emit_debug(event: String, detail: String) -> void:
	if not debug_logging:
		return
	voice_debug.emit(event, detail)


func _resolve_local_steam_id() -> int:
	if Engine.has_singleton("Steam"):
		var steam: Object = Engine.get_singleton("Steam")
		if steam.has_method("getSteamID"):
			return int(steam.call("getSteamID"))
	return 0


func _discover_peers_from_steam() -> Array[int]:
	var tree := get_tree()
	if tree == null:
		return []
	var mp := tree.get_multiplayer()
	if mp == null:
		return []
	return SteamMultiplayerPeerAdapter.collect_session_steam_ids(mp)
