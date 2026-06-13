extends Node3D

## Standalone demo: proximity (open mic + spatial) and radio (PTT + roster) channels.

@onready var session: VoiceSession = $VoiceSession
@onready var proximity: VoiceChannel = $VoiceSession/Proximity
@onready var radio: VoiceChannel = $VoiceSession/Radio


func _ready() -> void:
	if OS.get_environment("STEAM_PROXIMITY_VOICE_TEST") == "1":
		return
	_configure_radio_roster()
	session.set_session_peers(
		SteamMultiplayerPeerAdapter.collect_session_steam_ids(get_tree().get_multiplayer())
	)
	call_deferred("_begin_when_ready")


func _configure_radio_roster() -> void:
	var roster := radio.get_modifier_by_class_name(&"RosterModifier") as RosterModifier
	if roster == null:
		return
	roster.membership_fn = func() -> Array[int]:
		return SteamMultiplayerPeerAdapter.collect_session_steam_ids(
			get_tree().get_multiplayer()
		)


func _begin_when_ready() -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	session.begin_session()
	_register_local_listener()


func _register_local_listener() -> void:
	var local_id := multiplayer.get_unique_id()
	for node in get_tree().get_nodes_in_group("demo_player"):
		if not node is CharacterBody3D:
			continue
		var player := node as CharacterBody3D
		if player.get_multiplayer_authority() != local_id:
			continue
		var head: Node3D = player.get_node_or_null("Head") as Node3D
		if head != null:
			proximity.register_listener(head)
			radio.register_listener(head)


func register_demo_player(player: CharacterBody3D) -> void:
	var peer := multiplayer.multiplayer_peer
	if peer == null:
		return
	var steam_id := SteamMultiplayerPeerAdapter.get_steam_id_for_peer(
		peer,
		player.get_multiplayer_authority()
	)
	var head: Node3D = player.get_node_or_null("Head") as Node3D
	if steam_id == 0 or head == null:
		return
	if player.is_multiplayer_authority():
		proximity.register_listener(head)
		radio.register_listener(head)
	else:
		proximity.register_speaker(steam_id, head)
		radio.register_speaker(steam_id, head)


func _exit_tree() -> void:
	if session != null and session.is_active:
		session.end_session()
