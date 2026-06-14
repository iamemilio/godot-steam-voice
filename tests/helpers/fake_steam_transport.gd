class_name FakeSteamVoiceTransport
extends RefCounted

## Test double for SteamVoiceTransport — records sends and injects receive data.

var available: bool = true
var sent_packets: Array[Dictionary] = []
var decompress_count: int = 0
var _voice_data: PackedByteArray = PackedByteArray()
var _incoming_by_port: Dictionary = {}


func set_voice(data: PackedByteArray) -> void:
	_voice_data = data


func get_voice() -> PackedByteArray:
	if not available:
		return PackedByteArray()
	var data := _voice_data
	_voice_data = PackedByteArray()
	return data


func start_recording() -> void:
	pass


func stop_recording() -> void:
	pass


func send_packet(steam_id: int, data: PackedByteArray, p2p_channel: int) -> void:
	if not available or data.is_empty() or steam_id == 0:
		return
	sent_packets.append(
		{"steam_id": steam_id, "data": data.duplicate(), "p2p_port": p2p_channel}
	)


func queue_packet(p2p_port: int, steam_id: int, data: PackedByteArray) -> void:
	if not _incoming_by_port.has(p2p_port):
		_incoming_by_port[p2p_port] = []
	(_incoming_by_port[p2p_port] as Array).append(
		{"steam_id": steam_id, "data": data.duplicate(), "result": 1}
	)


func read_packets(p2p_channel: int, _max_packet_size: int = 8192) -> Array[Dictionary]:
	var queued: Array = _incoming_by_port.get(p2p_channel, [])
	_incoming_by_port[p2p_channel] = []
	var packets: Array[Dictionary] = []
	for packet_data in queued:
		packets.append(packet_data)
	return packets


func decompress_voice(compressed: PackedByteArray) -> Dictionary:
	decompress_count += 1
	if compressed.is_empty():
		return {}
	var buffer := PackedByteArray()
	buffer.resize(4)
	buffer.encode_s16(0, 16384)
	buffer.encode_s16(2, 16384)
	return {"buffer": buffer, "sample_rate": SteamVoiceTransport.DEFAULT_SAMPLE_RATE}
