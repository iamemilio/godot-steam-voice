class_name VoiceMember
extends Node

## Per-player voice position. Session wires head node to the voice channel automatically.

@export var head_path: NodePath = ^"../Head"
@export var steam_id: int = 0

var _registered: bool = false
var _session_started_hooked: bool = false


func _enter_tree() -> void:
	call_deferred("_register_with_session")


func _exit_tree() -> void:
	var session := _find_voice_session()
	if session != null:
		_unhook_session_started(session)
		if _registered:
			session.unbind_member(self)
	_registered = false


func get_head_node() -> Node3D:
	if head_path.is_empty():
		return null
	var node := get_node_or_null(head_path) as Node3D
	if node != null:
		return node
	var parent := get_parent()
	if parent != null:
		return parent.get_node_or_null(head_path) as Node3D
	return null


func resolve_steam_id() -> int:
	if steam_id != 0:
		return steam_id
	var authority := _authority_peer_id()
	if authority <= 0:
		return 0
	var tree := get_tree()
	if tree == null:
		return 0
	var mp := tree.get_multiplayer()
	if mp == null or mp.multiplayer_peer == null:
		return 0
	var peer := mp.multiplayer_peer
	if peer.has_method("get_steam_id_for_peer_id"):
		return int(peer.call("get_steam_id_for_peer_id", authority))
	return 0


func is_local_member() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	var mp := tree.get_multiplayer()
	if mp == null or not mp.has_multiplayer_peer():
		return true
	var authority := _authority_peer_id()
	return authority > 0 and authority == mp.get_unique_id()


func _authority_peer_id() -> int:
	## Prefer the playable body — Head children may not share authority if set pre-tree.
	var node: Node = _playable_root()
	if node == null:
		node = self
	return int(node.get_multiplayer_authority())


func _playable_root() -> Node:
	var node: Node = self
	while node != null:
		if node is CharacterBody3D:
			return node
		node = node.get_parent()
	return null


func _register_with_session() -> void:
	var session := _find_voice_session()
	if session == null:
		return
	_hook_session_started(session)
	var head := get_head_node()
	if head == null:
		return
	var resolved_id := resolve_steam_id()
	session.bind_member(resolved_id, head, is_local_member(), self)
	_registered = true


func _hook_session_started(session: VoiceSession) -> void:
	if _session_started_hooked or session == null:
		return
	if not session.session_started.is_connected(_on_session_started):
		session.session_started.connect(_on_session_started)
	_session_started_hooked = true


func _unhook_session_started(session: VoiceSession) -> void:
	if session != null and session.session_started.is_connected(_on_session_started):
		session.session_started.disconnect(_on_session_started)
	_session_started_hooked = false


func _on_session_started() -> void:
	# Re-bind after stop→start; steam_id / is_local may have been unresolved at first bind.
	_register_with_session()


func _find_voice_session() -> VoiceSession:
	var node := get_parent()
	while node != null:
		if node is VoiceSession:
			return node as VoiceSession
		node = node.get_parent()
	var tree := get_tree()
	if tree == null:
		return null
	var sessions := tree.get_nodes_in_group("voice_session")
	for session_node in sessions:
		if session_node is VoiceSession:
			return session_node as VoiceSession
	return null
