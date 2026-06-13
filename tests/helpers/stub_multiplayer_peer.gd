class_name StubMultiplayerPeer
extends RefCounted

## Duck-types GodotSteam MultiplayerPeer for adapter tests.

var _steam_ids: Dictionary = {}


func set_steam_id(peer_id: int, steam_id: int) -> void:
	_steam_ids[peer_id] = steam_id


func get_steam_id_for_peer_id(peer_id: int) -> int:
	return int(_steam_ids.get(peer_id, 0))
