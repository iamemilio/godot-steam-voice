class_name StubMultiplayerAPI
extends RefCounted

## Minimal MultiplayerAPI stand-in for adapter tests.

var multiplayer_peer: StubMultiplayerPeer
var peer_ids: Array[int] = []


func get_peers() -> PackedInt32Array:
	return PackedInt32Array(peer_ids)
