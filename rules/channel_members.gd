class_name ChannelMembers
extends VoiceRule

## Restricts who can talk and listen on this channel.


@export var membership: Array[int] = []
@export var membership_fn: Callable
@export var walkie_only: bool = false


func filter_recipients(ctx: VoiceSendContext) -> void:
	if walkie_only and (ctx.transmit_flags & VoicePacket.FLAG_WALKIE_ACTIVE) == 0:
		return
	var allowed := _resolve_membership()
	if allowed.is_empty():
		return
	var filtered: Array[int] = []
	for steam_id in ctx.recipients:
		if allowed.has(int(steam_id)):
			filtered.append(int(steam_id))
	ctx.recipients = filtered


func should_send(ctx: VoiceSendContext) -> bool:
	if walkie_only and (ctx.transmit_flags & VoicePacket.FLAG_WALKIE_ACTIVE) == 0:
		return true
	var allowed := _resolve_membership()
	if allowed.is_empty():
		return true
	return allowed.has(ctx.local_steam_id)


func process_playback_gain(ctx: VoicePlaybackContext) -> void:
	if walkie_only and (ctx.transmit_flags & VoicePacket.FLAG_WALKIE_ACTIVE) == 0:
		return
	var allowed := _resolve_membership()
	if allowed.is_empty():
		return
	if not allowed.has(ctx.speaker_steam_id):
		ctx.gain_multiplier = 0.0


func _resolve_membership() -> Array[int]:
	if membership_fn.is_valid():
		var result: Variant = membership_fn.call()
		if result is Array:
			var ids: Array[int] = []
			for item in result:
				ids.append(int(item))
			return ids
	return membership.duplicate()
