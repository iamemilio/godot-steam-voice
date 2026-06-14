class_name VoicePacket
extends RefCounted

## Voice P2P packet envelope: wire id, transmit flags, then Steam compressed bytes.

const FLAG_WALKIE_ACTIVE := 1
const MIN_SIZE := 3

const VOICE_P2P_PORT := 1


static func build(wire_id: int, flags: int, compressed: PackedByteArray) -> PackedByteArray:
	var packet := PackedByteArray()
	packet.append(wire_id & 0xFF)
	packet.append(flags & 0xFF)
	packet.append_array(compressed)
	return packet


static func parse(raw: PackedByteArray) -> Dictionary:
	if raw.size() < MIN_SIZE:
		return {}
	return {
		"wire_id": int(raw[0]),
		"flags": int(raw[1]),
		"compressed": raw.slice(2),
	}


static func payload_cache_key(sender_steam_id: int, compressed: PackedByteArray) -> String:
	var hasher := HashingContext.new()
	hasher.start(HashingContext.HASH_MD5)
	hasher.update(compressed)
	var digest := hasher.finish()
	return "%d:%d:%x" % [sender_steam_id, compressed.size(), digest.decode_u64(0)]
