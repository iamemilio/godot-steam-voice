class_name SteamMultiplayerPeerAdapter
extends RefCounted

## Helpers to resolve Steam IDs from GodotSteam MultiplayerPeer.


static func get_steam_id_for_peer(peer: Object, peer_id: int) -> int:
	if peer == null or not peer.has_method("get_steam_id_for_peer_id"):
		return 0
	return int(peer.call("get_steam_id_for_peer_id", peer_id))


static func collect_session_steam_ids(multiplayer_api: Object) -> Array[int]:
	var ids: Array[int] = []
	if multiplayer_api == null or not multiplayer_api.has_method("get_peers"):
		return ids
	var peer: Object = multiplayer_api.get("multiplayer_peer")
	if peer == null:
		return ids
	for peer_id in multiplayer_api.get_peers():
		var steam_id := get_steam_id_for_peer(peer, int(peer_id))
		if steam_id != 0 and not ids.has(steam_id):
			ids.append(steam_id)
	var host_steam_id := get_steam_id_for_peer(peer, 1)
	if host_steam_id != 0 and not ids.has(host_steam_id):
		ids.append(host_steam_id)
	return ids


static func register_players_from_tree(
	channel: Node,
	players_root: Node,
	head_path: NodePath,
	resolve_steam_id: Callable
) -> void:
	if channel == null or players_root == null or not resolve_steam_id.is_valid():
		return
	for child in players_root.get_children():
		var head: Node3D = child.get_node_or_null(head_path) as Node3D
		if head == null:
			continue
		var steam_id: int = int(resolve_steam_id.call(child))
		if steam_id != 0:
			channel.call("register_speaker", steam_id, head)
