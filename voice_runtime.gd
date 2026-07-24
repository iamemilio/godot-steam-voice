class_name VoiceRuntime
extends Node

## High-level voice controller.
##
## Configure [member config] in the Inspector, then call [method start] /
## [method stop] from code. Sibling [VoiceRuntime] nodes under the same parent
## share one [VoiceSession]; only one may be active at a time.

## Emitted after a successful [method start].
signal started()
## Emitted after [method stop] when this runtime was active.
signal stopped()
## Library log line. Also printed with the [code][godot-steam-voice][/code] prefix.
signal log_message(level: LogLevel, event: String, detail: String)

enum LogLevel {
	## No prints or [signal log_message] for routine traffic.
	OFF,
	## Start/stop and failures only.
	INFO,
	## INFO plus session debug events and a throttled heartbeat.
	DEBUG,
}

const LOG_PREFIX := "[godot-steam-voice]"
const DEFAULT_HEARTBEAT_MSEC := 2000

## Binding and proximity blueprint. New Resource ships game-ready proximity.
@export var config: VoiceContextConfig

## How much the runtime logs. Prefer OFF in shipping builds.
@export var log_level: LogLevel = LogLevel.OFF

## DEBUG heartbeat period in milliseconds.
@export_range(250, 60000, 50, "or_greater", "suffix:ms")
var heartbeat_interval_msec: int = DEFAULT_HEARTBEAT_MSEC

var _peers: Array[int] = []
var _active: bool = false
var _session: VoiceSession
var _ephemeral_rig: Node3D
var _ephemeral_listener: Node3D
## Single shared anchor for all remote ephemeral speakers (same origin).
var _ephemeral_speaker_anchor: Node3D
var _voice_debug_connected: bool = false
var _debug_last_msec: int = 0
var _debug_sent_frames: int = 0
var _debug_recv_packets: int = 0
var _debug_empty_peer_ticks: int = 0


func _ready() -> void:
	set_process(false)


func _process(_delta: float) -> void:
	_maybe_emit_heartbeat()


func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE and _active:
		stop()


## Applies [member config], starts the shared session, and binds speakers.
func start() -> void:
	if config == null:
		_emit_log(LogLevel.INFO, "start_failed", "config is null")
		return
	if _active:
		refresh()
		return

	_stop_sibling_runtimes()
	_session = _ensure_session()
	if _session == null:
		_emit_log(LogLevel.INFO, "start_failed", "no VoiceSession")
		return

	_apply_channel_exports()
	_session.set_session_peers(_peers)
	_session.debug_logging = log_level == LogLevel.DEBUG
	_hook_voice_debug()

	if _session.is_active:
		_session.stop()
	_session.start()
	if not _session.is_active:
		_emit_log(LogLevel.INFO, "start_failed", "VoiceSession.start() did not activate")
		return

	_apply_proximity_rule_volumes()
	_apply_binding()
	_active = true
	_reset_debug_counters()
	set_process(log_level == LogLevel.DEBUG)
	started.emit()
	_emit_log(LogLevel.INFO, "started", _label_detail())


## Stops voice and frees ephemeral anchors. Idempotent.
func stop() -> void:
	if not _active:
		_teardown_ephemeral()
		return

	_teardown_ephemeral()
	if _session != null:
		_session.set_session_peers([])
		if _session.is_active:
			_session.stop()
		_unhook_voice_debug()
	_active = false
	set_process(false)
	_reset_debug_counters()
	stopped.emit()
	_emit_log(LogLevel.INFO, "stopped", _label_detail())


## True when this runtime owns the live shared session.
func is_active() -> bool:
	return _active and _session != null and _session.is_active


## Re-applies peers and binding while active (e.g. after a peer joins).
func refresh() -> void:
	if not is_active():
		return
	_session.set_session_peers(_peers)
	_apply_binding()
	_emit_log(LogLevel.DEBUG, "refreshed", "peers=%s" % str(_peers))


## Sets the Steam ID roster used for send targets and ephemeral speaker binds.
func set_peers(steam_ids: Array[int]) -> void:
	_peers = steam_ids.duplicate()
	if is_active():
		_session.set_session_peers(_peers)
		_apply_binding()


## Returns the shared [VoiceSession], creating it under the parent if needed.
func get_session() -> VoiceSession:
	return _ensure_session()


## Updates [member log_level] and session debug forwarding.
func set_log_level(level: LogLevel) -> void:
	log_level = level
	if _session != null:
		_session.debug_logging = level == LogLevel.DEBUG
	set_process(_active and level == LogLevel.DEBUG)


func get_log_level() -> LogLevel:
	return log_level


func _stop_sibling_runtimes() -> void:
	var parent := get_parent()
	if parent == null:
		return
	for child in parent.get_children():
		if child == self:
			continue
		if child is VoiceRuntime:
			(child as VoiceRuntime).stop()


func _ensure_session() -> VoiceSession:
	if _session != null and is_instance_valid(_session):
		_ensure_channel(_session)
		return _session

	var parent := get_parent()
	if parent != null:
		for child in parent.get_children():
			if child is VoiceSession:
				_session = child as VoiceSession
				_ensure_channel(_session)
				return _session

	_session = VoiceSession.new()
	_session.name = "VoiceSession"
	if parent != null:
		parent.add_child(_session)
	else:
		add_child(_session)
	_ensure_channel(_session)
	return _session


func _ensure_channel(session: VoiceSession) -> VoiceChannel:
	for child in session.get_children():
		if child is VoiceChannel:
			return child as VoiceChannel
	var channel := VoiceChannel.new()
	channel.name = "Voice"
	channel.channel_name = "Voice"
	session.add_child(channel)
	return channel


func _apply_channel_exports() -> void:
	var channel := _ensure_channel(_session)
	if channel == null or config == null:
		return

	if config.is_proximity_active():
		var prox_cfg: ProximityConfiguration = config.proximity.configuration
		channel.preset = VoiceChannel.Preset.PROXIMITY
		channel.near_full_volume_m = prox_cfg.full_volume_buffer_radius_m
		channel.far_silent_m = prox_cfg.max_range_m
		channel.use_wall_muffling = prox_cfg.use_wall_muffling
	else:
		channel.preset = VoiceChannel.Preset.GLOBAL
		channel.use_wall_muffling = false


func _apply_proximity_rule_volumes() -> void:
	if config == null or not config.is_proximity_active() or _session == null:
		return
	var channel := _session.get_primary_channel()
	if channel == null:
		return
	var prox_cfg: ProximityConfiguration = config.proximity.configuration
	var rule := channel.get_rule_by_class_name(&"ProximityVolume") as ProximityVolume
	if rule == null:
		return
	rule.full_volume_m = prox_cfg.full_volume_buffer_radius_m
	rule.silent_m = prox_cfg.max_range_m
	rule.min_volume_db = prox_cfg.min_volume_db
	rule.max_volume_db = prox_cfg.max_volume_db


func _apply_binding() -> void:
	if config == null or _session == null:
		return
	match config.binding:
		VoiceContextConfig.Binding.MEMBERS:
			_teardown_ephemeral()
			_session.refresh_member_bindings()
		VoiceContextConfig.Binding.EPHEMERAL_CLUSTER:
			_bind_ephemeral_cluster()
		VoiceContextConfig.Binding.MANUAL:
			_teardown_ephemeral()
		_:
			pass


func _bind_ephemeral_cluster() -> void:
	_ensure_ephemeral_rig()
	var channel := _session.get_primary_channel()
	if channel == null or _ephemeral_listener == null or _ephemeral_speaker_anchor == null:
		return
	channel.clear_speakers()
	channel.register_listener(_ephemeral_listener)
	var local_id := _session.local_steam_id
	for steam_id in _peers:
		var id := int(steam_id)
		if id == 0 or id == local_id:
			continue
		# All remotes share one origin anchor — avoids N duplicate Node3Ds.
		channel.register_speaker(id, _ephemeral_speaker_anchor)


func _ensure_ephemeral_rig() -> void:
	if _ephemeral_rig != null and is_instance_valid(_ephemeral_rig):
		return
	_ephemeral_rig = Node3D.new()
	_ephemeral_rig.name = "EphemeralVoiceRig"
	add_child(_ephemeral_rig)
	_ephemeral_listener = Node3D.new()
	_ephemeral_listener.name = "EphemeralListener"
	_ephemeral_rig.add_child(_ephemeral_listener)
	_ephemeral_speaker_anchor = Node3D.new()
	_ephemeral_speaker_anchor.name = "EphemeralSpeakers"
	_ephemeral_speaker_anchor.position = Vector3.ZERO
	_ephemeral_rig.add_child(_ephemeral_speaker_anchor)


func _teardown_ephemeral() -> void:
	_ephemeral_listener = null
	_ephemeral_speaker_anchor = null
	if _ephemeral_rig != null and is_instance_valid(_ephemeral_rig):
		_ephemeral_rig.queue_free()
	_ephemeral_rig = null


func _hook_voice_debug() -> void:
	if _session == null or _voice_debug_connected:
		return
	if not _session.voice_debug.is_connected(_on_session_voice_debug):
		_session.voice_debug.connect(_on_session_voice_debug)
	_voice_debug_connected = true


func _unhook_voice_debug() -> void:
	if _session == null or not _voice_debug_connected:
		return
	if _session.voice_debug.is_connected(_on_session_voice_debug):
		_session.voice_debug.disconnect(_on_session_voice_debug)
	_voice_debug_connected = false


func _on_session_voice_debug(event: String, detail: String) -> void:
	match event:
		"send_frame":
			_debug_sent_frames += 1
		"recv_packet":
			_debug_recv_packets += 1
		"empty_peers":
			_debug_empty_peer_ticks += 1
		_:
			_emit_log(LogLevel.DEBUG, event, detail)


func _maybe_emit_heartbeat() -> void:
	if log_level != LogLevel.DEBUG or not is_active():
		return
	var now := Time.get_ticks_msec()
	if now - _debug_last_msec < heartbeat_interval_msec:
		return
	_debug_last_msec = now
	var channel := _session.get_primary_channel()
	var speakers: Array = []
	var has_listener := false
	if channel != null:
		speakers = channel.get_registered_speaker_ids()
		has_listener = channel.get_listener_node() != null
	_emit_log(
		LogLevel.DEBUG,
		"heartbeat",
		(
			"sent=%d recv=%d empty_peers=%d peers=%s speakers=%s listener=%s"
			% [
				_debug_sent_frames,
				_debug_recv_packets,
				_debug_empty_peer_ticks,
				_session.get_session_peers(),
				speakers,
				has_listener,
			]
		)
	)
	_debug_sent_frames = 0
	_debug_recv_packets = 0
	_debug_empty_peer_ticks = 0


func _reset_debug_counters() -> void:
	_debug_sent_frames = 0
	_debug_recv_packets = 0
	_debug_empty_peer_ticks = 0
	_debug_last_msec = 0


func _label_detail() -> String:
	if config != null and config.label != &"":
		return String(config.label)
	return name


func _emit_log(level: LogLevel, event: String, detail: String) -> void:
	if log_level == LogLevel.OFF:
		return
	if level == LogLevel.DEBUG and log_level != LogLevel.DEBUG:
		return
	log_message.emit(level, event, detail)
	if detail.is_empty():
		print("%s %s" % [LOG_PREFIX, event])
	else:
		print("%s %s %s" % [LOG_PREFIX, event, detail])
