class_name VoiceMember
extends Node

## Per-player voice position. Session wires head node to the voice channel automatically.

@export var head_path: NodePath = ^"../Head"
@export var steam_id: int = 0

var _registered: bool = false


func _enter_tree() -> void:
	call_deferred("_register_with_session")


func _exit_tree() -> void:
	var session := _find_voice_session()
	if session != null and _registered:
		session.unbind_member(self)


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
	if has_method("get_multiplayer_authority"):
		var authority := int(get_multiplayer_authority())
		if authority > 0:
			var tree := get_tree()
			if tree != null:
				var mp := tree.get_multiplayer()
				if mp != null and mp.multiplayer_peer != null:
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
	return int(get_multiplayer_authority()) == mp.get_unique_id()


func _register_with_session() -> void:
	var session := _find_voice_session()
	if session == null:
		return
	var head := get_head_node()
	if head == null:
		return
	var resolved_id := resolve_steam_id()
	session.bind_member(resolved_id, head, is_local_member(), self)
	_registered = true


func _find_voice_session() -> VoiceSession:
	var node := get_parent()
	while node != null:
		if node is VoiceSession:
			return node as VoiceSession
		node = node.get_parent()
	var tree := get_tree()
	if tree == null:
		return null
	node = self
	while node != null:
		if node.has_method("start") and node.has_method("get_primary_channel"):
			return node as VoiceSession
		node = node.get_parent()
	return null
