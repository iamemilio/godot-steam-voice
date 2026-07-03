class_name SteamVoiceTransport
extends RefCounted

## Isolates GodotSteam voice + P2P calls. No-ops when Steam is unavailable (CI / editor).

const DEFAULT_SAMPLE_RATE := 24000

var available: bool = false
var _steam: Object


func _init() -> void:
	if Engine.has_singleton("Steam"):
		_steam = Engine.get_singleton("Steam")
		available = _steam != null


func start_recording() -> void:
	if not available:
		return
	_steam.call("startVoiceRecording")


func stop_recording() -> void:
	if not available:
		return
	_steam.call("stopVoiceRecording")


func get_voice() -> PackedByteArray:
	if not available:
		return PackedByteArray()
	var result: Variant = _steam.call("getVoice")
	if result is Dictionary:
		var data: Dictionary = result
		var buffer: PackedByteArray = data.get("buffer", PackedByteArray()) as PackedByteArray
		if not buffer.is_empty():
			return buffer
	return PackedByteArray()


func decompress_voice(compressed: PackedByteArray) -> Dictionary:
	if not available or compressed.is_empty():
		return {}
	var sample_rate := DEFAULT_SAMPLE_RATE
	if _steam.has_method("getVoiceOptimalSampleRate"):
		sample_rate = int(_steam.call("getVoiceOptimalSampleRate"))
	var result: Variant = _steam.call("decompressVoice", compressed, sample_rate, 20480)
	if not result is Dictionary:
		return {}
	var data: Dictionary = result
	var pcm_size := int(data.get("size", 0))
	if pcm_size <= 0:
		return {}
	if int(data.get("result", -1)) != _voice_result_ok():
		return {}
	var pcm: PackedByteArray = data.get("uncompressed", PackedByteArray()) as PackedByteArray
	if pcm.is_empty():
		pcm = data.get("buffer", PackedByteArray()) as PackedByteArray
	if pcm.is_empty():
		return {}
	return {"buffer": pcm.slice(0, pcm_size), "sample_rate": sample_rate}


func _voice_result_ok() -> int:
	if _steam.get("VoiceResult") != null:
		var voice_result = _steam.get("VoiceResult")
		if voice_result is Dictionary and voice_result.has("VOICE_RESULT_OK"):
			return int(voice_result["VOICE_RESULT_OK"])
	if _steam.get("VOICE_RESULT_OK") != null:
		return int(_steam.get("VOICE_RESULT_OK"))
	return 0


func send_packet(steam_id: int, data: PackedByteArray, p2p_channel: int) -> void:
	if not available or data.is_empty() or steam_id == 0:
		return
	var send_type := _p2p_send_unreliable_no_delay()
	_steam.call("sendP2PPacket", steam_id, data, send_type, p2p_channel)


func read_packets(p2p_channel: int, max_packet_size: int = 8192) -> Array[Dictionary]:
	var packets: Array[Dictionary] = []
	if not available:
		return packets
	while true:
		var result: Variant = _steam.call("readP2PPacket", max_packet_size, p2p_channel)
		if not result is Dictionary:
			break
		var data: Dictionary = result
		if int(data.get("result", 0)) == 0:
			break
		packets.append(data)
	return packets


static func pcm_bytes_to_mono_floats(buffer: PackedByteArray) -> PackedFloat32Array:
	var sample_count := buffer.size() / 2
	var out := PackedFloat32Array()
	out.resize(sample_count)
	for i in sample_count:
		var offset := i * 2
		var sample := buffer.decode_s16(offset)
		out[i] = float(sample) / 32768.0
	return out


static func pcm_floats_to_stereo_frames(samples: PackedFloat32Array) -> Array[Vector2]:
	var frames: Array[Vector2] = []
	frames.resize(samples.size())
	for i in samples.size():
		var s := samples[i]
		frames[i] = Vector2(s, s)
	return frames


func _p2p_send_unreliable_no_delay() -> int:
	if _steam.get("P2P_SEND_UNRELIABLE_NO_DELAY") != null:
		return int(_steam.get("P2P_SEND_UNRELIABLE_NO_DELAY"))
	# GodotSteam 4.x P2P_SEND_UNRELIABLE_NO_DELAY fallback
	return 2
