class_name VoiceChannel
extends Node

## One voice stream: preset-driven rules or CUSTOM rule stack. Client-owned playback effects.

signal speaker_registered(steam_id: int)
signal speaker_unregistered(steam_id: int)

enum Preset {
	GLOBAL,
	PROXIMITY,
	CUSTOM,
}

@export var channel_name: String = "Voice"
@export var enabled: bool = true
@export var preset: Preset = Preset.PROXIMITY

@export_group("Proximity voice")
@export var near_full_volume_m: float = 5.0
@export var far_silent_m: float = 30.0

@export_group("Wall muffling")
@export var use_wall_muffling: bool = false

@export_group("Walkie")
@export var use_walkie: bool = false
@export var push_to_talk_action: String = "radio_push"
@export var effects_bus_name: String = "VoiceRadio"
@export var walkie_use_channel_members: bool = false
@export var walkie_membership: Array[int] = []

@export_group("Custom")
@export var rules: Array[VoiceRule] = []

var wire_id: int = -1
var p2p_port: int = -1

var _session: Node
var _listener_node: Node3D
var _speakers: Dictionary = {}
var _speaker_handles: Dictionary = {}
var _active_rules: Array[VoiceRule] = []
var _speaker_transmit_flags: Dictionary = {}


func _ready() -> void:
	_session = _find_session_parent()
	_rebuild_preset_rules()


func _find_session_parent() -> Node:
	var node := get_parent()
	while node != null:
		if node.has_method("start") and node.has_method("get_channel"):
			return node
		node = node.get_parent()
	return null


func _rebuild_preset_rules() -> void:
	if preset == Preset.CUSTOM:
		_active_rules = rules.duplicate()
		return
	_active_rules.clear()
	match preset:
		Preset.GLOBAL:
			var mic := MicMode.new()
			mic.open_mic_enabled = true
			_active_rules.append(mic)
		Preset.PROXIMITY:
			var prox := ProximityVolume.new()
			prox.full_volume_m = near_full_volume_m
			prox.silent_m = far_silent_m
			_active_rules.append(prox)
			if use_wall_muffling:
				_active_rules.append(WallMuffling.new())
			var mic_mode := MicMode.new()
			mic_mode.open_mic_enabled = true
			if use_walkie and not push_to_talk_action.is_empty():
				mic_mode.walkie_ptt_action = push_to_talk_action
			_active_rules.append(mic_mode)
			if use_walkie:
				var bus := VoiceEffectsBus.new()
				bus.bus_name = effects_bus_name
				bus.walkie_only = true
				_active_rules.append(bus)
				if walkie_use_channel_members:
					var members := ChannelMembers.new()
					members.membership = walkie_membership.duplicate()
					members.walkie_only = true
					_active_rules.append(members)


func register_listener(node: Node3D) -> void:
	if node == null:
		_listener_node = null
		return
	_listener_node = node


func register_speaker(steam_id: int, node: Node3D) -> void:
	if steam_id == 0:
		return
	_speakers[steam_id] = node
	speaker_registered.emit(steam_id)


func unregister_speaker(steam_id: int) -> void:
	_speakers.erase(steam_id)
	_speaker_transmit_flags.erase(steam_id)
	if _speaker_handles.has(steam_id):
		(_speaker_handles[steam_id] as VoiceSpeakerHandle).cleanup()
		_speaker_handles.erase(steam_id)
	speaker_unregistered.emit(steam_id)


func clear_speakers() -> void:
	for steam_id in _speaker_handles.keys():
		(_speaker_handles[steam_id] as VoiceSpeakerHandle).cleanup()
	_speaker_handles.clear()
	_speakers.clear()
	_speaker_transmit_flags.clear()


func get_listener_node() -> Node3D:
	return _listener_node


func get_speaker_node(steam_id: int) -> Node3D:
	return _speakers.get(steam_id) as Node3D


func get_registered_speaker_ids() -> Array[int]:
	var ids: Array[int] = []
	for steam_id in _speakers.keys():
		ids.append(int(steam_id))
	return ids


func get_effective_rules() -> Array[VoiceRule]:
	if preset == Preset.CUSTOM:
		return rules
	return _active_rules


func get_rule_by_class_name(type_name: StringName) -> VoiceRule:
	for rule in get_effective_rules():
		if rule == null:
			continue
		if rule.get_class() == type_name:
			return rule
		var rule_script: Script = rule.get_script()
		if rule_script != null and rule_script.get_global_name() == type_name:
			return rule
	return null


func set_rule_enabled(type_name: StringName, is_enabled: bool) -> void:
	var rule := get_rule_by_class_name(type_name)
	if rule != null:
		rule.enabled = is_enabled


func bind_session(session: Node) -> void:
	_session = session


func notify_registered() -> void:
	_rebuild_preset_rules()
	for rule in get_effective_rules():
		if rule != null:
			rule.on_channel_registered(self, _session)


func notify_unregistered() -> void:
	for rule in get_effective_rules():
		if rule != null:
			rule.on_channel_unregistered()
	clear_speakers()


func process_rules_frame(delta: float) -> void:
	if _session == null:
		return
	for rule in get_effective_rules():
		if rule != null and rule.enabled:
			rule.process_frame(delta, self, _session)


func evaluate_send(ctx: VoiceSendContext) -> bool:
	if not enabled:
		return false
	if ctx.compressed_voice.is_empty():
		return false
	ctx.transmit_flags = 0
	for rule in get_effective_rules():
		if rule == null or not rule.enabled:
			continue
		if not rule.should_send(ctx):
			return false
	for rule in get_effective_rules():
		if rule == null or not rule.enabled:
			continue
		rule.apply_transmit_flags(ctx)
	for rule in get_effective_rules():
		if rule == null or not rule.enabled:
			continue
		rule.filter_recipients(ctx)
	if ctx.blocked:
		return false
	return not ctx.recipients.is_empty()


func set_speaker_transmit_flags(steam_id: int, flags: int) -> void:
	_speaker_transmit_flags[steam_id] = flags


func evaluate_playback(ctx: VoicePlaybackContext, handle: VoiceSpeakerHandle) -> void:
	ctx.gain_multiplier = 1.0
	ctx.volume_db_offset = 0.0
	ctx.audio_bus = "Master"
	ctx.transmit_flags = int(_speaker_transmit_flags.get(ctx.speaker_steam_id, 0))
	for rule in get_effective_rules():
		if rule == null or not rule.enabled:
			continue
		rule.configure_playback(ctx, handle)
		rule.process_playback_gain(ctx)


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
