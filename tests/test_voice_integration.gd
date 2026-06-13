class_name TestVoiceIntegration
extends RefCounted

## Scene-tree integration tests (no live Steam required).

const VoiceSessionScript := preload("res://voice_session.gd")
const VoiceChannelScript := preload("res://voice_channel.gd")
const SpatialAttenuationModifierScript := preload("res://modifiers/spatial_attenuation_modifier.gd")
const VoiceInputModifierScript := preload("res://modifiers/voice_input_modifier.gd")
const RosterModifierScript := preload("res://modifiers/roster_modifier.gd")
const RoomOcclusionModifierScript := preload("res://modifiers/room_occlusion_modifier.gd")


func run(tree: SceneTree) -> int:
	var failures := 0
	failures += _test_channel_auto_allocation(tree)
	failures += _test_spatial_playback_with_registered_speakers(tree)
	failures += _test_send_pipeline_roster_and_ptt()
	failures += _test_proximity_channel_wiring(tree)
	failures += _test_demo_scene_loads()
	return failures


func _test_channel_auto_allocation(tree: SceneTree) -> int:
	var session: VoiceSession = VoiceSessionScript.new()
	var proximity: VoiceChannel = VoiceChannelScript.new()
	proximity.channel_name = "Proximity"
	var radio: VoiceChannel = VoiceChannelScript.new()
	radio.channel_name = "Radio"
	session.add_child(proximity)
	session.add_child(radio)
	tree.root.add_child(session)

	session._discover_channels()
	session._allocate_channel_ids()

	if proximity.wire_id != 1 or proximity.p2p_port != 1:
		push_error("Expected Proximity wire_id=1 p2p_port=1")
		_cleanup_session(session)
		return 1
	if radio.wire_id != 2 or radio.p2p_port != 2:
		push_error("Expected Radio wire_id=2 p2p_port=2")
		_cleanup_session(session)
		return 1
	if session.get_channel("Proximity") != proximity:
		push_error("Expected get_channel to resolve Proximity")
		_cleanup_session(session)
		return 1

	_cleanup_session(session)
	return 0


func _test_spatial_playback_with_registered_speakers(tree: SceneTree) -> int:
	var session: VoiceSession = VoiceSessionScript.new()
	var channel: VoiceChannel = VoiceChannelScript.new()
	var spatial: SpatialAttenuationModifier = SpatialAttenuationModifierScript.new()
	spatial.full_volume_m = 3.0
	spatial.silent_m = 25.0
	channel.modifiers = [spatial]
	session.add_child(channel)
	tree.root.add_child(session)
	session._discover_channels()
	channel.bind_session(session)

	var listener := Node3D.new()
	var speaker := Node3D.new()
	listener.position = Vector3.ZERO
	speaker.position = Vector3(30.0, 0.0, 0.0)
	tree.root.add_child(listener)
	tree.root.add_child(speaker)

	channel.register_listener(listener)
	channel.register_speaker(42, speaker)
	channel.get_or_create_handle(42)
	channel.update_playback()

	var handle := channel.get_speaker_handle(42)
	if handle == null or handle.player == null:
		push_error("Expected speaker playback handle")
		_cleanup_nodes([session, listener, speaker])
		return 1
	if handle.player.volume_db > -10.0:
		push_error("Expected low volume_db for distant speaker")
		_cleanup_nodes([session, listener, speaker])
		return 1

	speaker.position = Vector3(2.0, 0.0, 0.0)
	channel.update_playback()
	if handle.player.volume_db < -3.0:
		push_error("Expected louder volume_db when speaker moved close")
		_cleanup_nodes([session, listener, speaker])
		return 1

	_cleanup_nodes([session, listener, speaker])
	return 0


func _test_send_pipeline_roster_and_ptt() -> int:
	var channel: VoiceChannel = VoiceChannelScript.new()
	var roster: RosterModifier = RosterModifierScript.new()
	roster.membership = [100, 200]
	var input_mod: VoiceInputModifier = VoiceInputModifierScript.new()
	input_mod.input_mode = VoiceInputModifier.InputMode.PUSH_TO_TALK
	channel.modifiers = [input_mod, roster]

	var ctx := VoiceSendContext.new()
	ctx.compressed_voice = PackedByteArray([1, 2, 3])
	ctx.local_steam_id = 100
	ctx.recipients = [100, 200, 300]

	if channel.evaluate_send(ctx):
		push_error("PTT should block send when key not held")
		return 1

	input_mod.input_mode = VoiceInputModifier.InputMode.OPEN_MIC
	ctx.recipients = [100, 200, 300]
	if not channel.evaluate_send(ctx):
		push_error("Open mic should allow send for roster member")
		return 1
	if ctx.recipients.has(300):
		push_error("Roster should filter out steam_id 300")
		return 1

	ctx.local_steam_id = 999
	ctx.recipients = [100, 200, 300]
	if channel.evaluate_send(ctx):
		push_error("Roster should block send when local steam_id not on roster")
		return 1

	return 0


func _test_proximity_channel_wiring(tree: SceneTree) -> int:
	var session: VoiceSession = VoiceSessionScript.new()
	var proximity: VoiceChannel = VoiceChannelScript.new()
	proximity.channel_name = "Proximity"
	var spatial: SpatialAttenuationModifier = SpatialAttenuationModifierScript.new()
	var mods: Array[VoiceModifier] = [spatial, RoomOcclusionModifierScript.new()]
	proximity.modifiers = mods
	session.add_child(proximity)
	tree.root.add_child(session)

	if proximity.modifiers.size() != 2:
		push_error("Proximity channel should have spatial + room occlusion modifiers")
		_cleanup_session(session)
		return 1
	if proximity.modifiers[0].get_script() != SpatialAttenuationModifierScript:
		push_error("Proximity channel should include SpatialAttenuationModifier")
		_cleanup_session(session)
		return 1

	_cleanup_session(session)
	return 0


func _test_demo_scene_loads() -> int:
	var scene := load("res://demo/demo.tscn") as PackedScene
	if scene == null:
		push_error("Demo scene should load")
		return 1
	var instance := scene.instantiate()
	if instance == null:
		push_error("Demo scene should instantiate")
		return 1
	if instance.get_node_or_null("VoiceSession/Proximity") == null:
		push_error("Demo scene should contain VoiceSession/Proximity channel")
		instance.free()
		return 1
	if instance.get_node_or_null("VoiceSession/Radio") == null:
		push_error("Demo scene should contain VoiceSession/Radio channel")
		instance.free()
		return 1
	instance.free()
	return 0


func _cleanup_session(session: VoiceSession) -> void:
	session.queue_free()


func _cleanup_nodes(nodes: Array) -> void:
	for node in nodes:
		if node is Node:
			(node as Node).queue_free()
