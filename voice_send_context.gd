class_name VoiceSendContext
extends RefCounted

## Passed to send-side rules each frame.

var channel: Node
var session: Node
var compressed_voice: PackedByteArray = PackedByteArray()
var local_steam_id: int = 0
var all_steam_ids: Array[int] = []
var recipients: Array[int] = []
var blocked: bool = false
var transmit_flags: int = 0


func duplicate_for_channel() -> VoiceSendContext:
	var copy := VoiceSendContext.new()
	copy.channel = channel
	copy.session = session
	copy.compressed_voice = compressed_voice
	copy.local_steam_id = local_steam_id
	copy.all_steam_ids = all_steam_ids.duplicate()
	copy.recipients = all_steam_ids.duplicate()
	copy.blocked = false
	copy.transmit_flags = 0
	return copy
