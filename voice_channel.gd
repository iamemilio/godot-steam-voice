class_name VoiceChannel
extends Node

## One comms mode: stack VoiceModifier resources and register listener/speaker Node3D refs.

signal speaker_registered(steam_id: int)
signal speaker_unregistered(steam_id: int)

@export var channel_name: String = "Default"
@export var enabled: bool = true
@export var modifiers: Array[VoiceModifier] = []

var wire_id: int = -1
var p2p_port: int = -1

var _session: Node
var _listener_node: Node3D
var _speakers: Dictionary = {}
var _speaker_handles: Dictionary = {}


func _ready() -> void:
	_session = _find_session_parent()


func _find_session_parent() -> Node:
	var node := get_parent()
	while node != null:
		if node.has_method("begin_session") and node.has_method("get_channel"):
			return node
		node = node.get_parent()
	return null


func register_listener(node: Node3D) -> void:
	_listener_node = node


func register_speaker(steam_id: int, node: Node3D) -> void:
	if steam_id == 0:
		return
	_speakers[steam_id] = node
	speaker_registered.emit(steam_id)


func unregister_speaker(steam_id: int) -> void:
	_speakers.erase(steam_id)
	if _speaker_handles.has(steam_id):
		(_speaker_handles[steam_id] as VoiceSpeakerHandle).cleanup()
		_speaker_handles.erase(steam_id)
	speaker_unregistered.emit(steam_id)


func clear_speakers() -> void:
	for steam_id in _speaker_handles.keys():
		(_speaker_handles[steam_id] as VoiceSpeakerHandle).cleanup()
	_speaker_handles.clear()
	_speakers.clear()


func get_listener_node() -> Node3D:
	return _listener_node


func get_speaker_node(steam_id: int) -> Node3D:
	return _speakers.get(steam_id) as Node3D


func get_registered_speaker_ids() -> Array[int]:
	var ids: Array[int] = []
	for steam_id in _speakers.keys():
		ids.append(int(steam_id))
	return ids


func get_modifier_by_class_name(type_name: StringName) -> VoiceModifier:
	for mod in modifiers:
		if mod != null and mod.get_class() == type_name:
			return mod
	return null


func set_modifier_enabled(type_name: StringName, is_enabled: bool) -> void:
	var mod := get_modifier_by_class_name(type_name)
	if mod != null:
		mod.enabled = is_enabled


func bind_session(session: Node) -> void:
	_session = session


func notify_registered() -> void:
	for mod in modifiers:
		if mod != null:
			mod.on_channel_registered(self, _session)


func notify_unregistered() -> void:
	for mod in modifiers:
		if mod != null:
			mod.on_channel_unregistered()
	clear_speakers()


func process_modifiers_frame(delta: float) -> void:
	if _session == null:
		return
	for mod in modifiers:
		if mod != null and mod.enabled:
			mod.process_frame(delta, self, _session)


func evaluate_send(ctx: VoiceSendContext) -> bool:
	if not enabled:
		return false
	if ctx.compressed_voice.is_empty():
		return false
	for mod in modifiers:
		if mod == null or not mod.enabled:
			continue
		if not mod.should_send(ctx):
			return false
		mod.filter_recipients(ctx)
	if ctx.blocked:
		return false
	return not ctx.recipients.is_empty()


func evaluate_playback(ctx: VoicePlaybackContext, handle: VoiceSpeakerHandle) -> void:
	ctx.gain_multiplier = 1.0
	ctx.volume_db_offset = 0.0
	ctx.audio_bus = "Master"
	ctx.use_spatial_player = false
	for mod in modifiers:
		if mod == null or not mod.enabled:
			continue
		mod.configure_playback(ctx, handle)
		mod.process_playback_gain(ctx)


func get_or_create_handle(steam_id: int) -> VoiceSpeakerHandle:
	if _speaker_handles.has(steam_id):
		return _speaker_handles[steam_id] as VoiceSpeakerHandle
	var handle := VoiceSpeakerHandle.new()
	var attach := get_speaker_node(steam_id)
	var parent: Node3D = attach if attach != null else _listener_node
	if parent == null:
		return handle
	handle.setup(parent, steam_id, attach)
	_speaker_handles[steam_id] = handle
	return handle


func get_speaker_handle(steam_id: int) -> VoiceSpeakerHandle:
	return _speaker_handles.get(steam_id) as VoiceSpeakerHandle


func update_playback() -> void:
	if _listener_node == null or not is_instance_valid(_listener_node):
		return
	var listener_pos := _listener_node.global_position
	for steam_id in _speaker_handles.keys():
		var handle := _speaker_handles[steam_id] as VoiceSpeakerHandle
		var speaker_node := get_speaker_node(steam_id)
		if speaker_node == null or not is_instance_valid(speaker_node):
			continue
		var ctx := VoicePlaybackContext.new()
		ctx.channel = self
		ctx.session = _session
		ctx.speaker_steam_id = int(steam_id)
		ctx.listener_position = listener_pos
		ctx.speaker_position = speaker_node.global_position
		ctx.listener_node = _listener_node
		ctx.speaker_node = speaker_node
		evaluate_playback(ctx, handle)
		var linear_gain := ctx.gain_multiplier
		var volume_db := linear_to_db(maxf(linear_gain, 0.00001)) + ctx.volume_db_offset
		handle.apply_volume_db(volume_db, ctx.audio_bus)
		handle.flush_to_playback()
