class_name TestModifierStack
extends RefCounted

const VoicePlaybackContextScript := preload("res://voice_playback_context.gd")
const VoiceSendContextScript := preload("res://voice_send_context.gd")
const SpatialAttenuationModifierScript := preload("res://modifiers/spatial_attenuation_modifier.gd")
const GainModifierScript := preload("res://modifiers/gain_modifier.gd")
const VoiceInputModifierScript := preload("res://modifiers/voice_input_modifier.gd")


func run() -> int:
	var failures := 0
	failures += _test_gain_stack_multiplies()
	failures += _test_open_mic_allows_send()
	failures += _test_ptt_blocks_send_when_not_held()
	return failures


func _test_gain_stack_multiplies() -> int:
	var spatial: SpatialAttenuationModifier = SpatialAttenuationModifierScript.new()
	spatial.full_volume_m = 3.0
	spatial.silent_m = 25.0
	var gain_mod: GainModifier = GainModifierScript.new()
	gain_mod.gain_db = -6.0
	var ctx: VoicePlaybackContext = VoicePlaybackContextScript.new()
	ctx.listener_position = Vector3.ZERO
	ctx.speaker_position = Vector3(2, 0, 0)
	ctx.gain_multiplier = 1.0
	ctx.volume_db_offset = 0.0
	spatial.process_playback_gain(ctx)
	gain_mod.process_playback_gain(ctx)
	if ctx.gain_multiplier < 0.99:
		push_error("Expected near-full spatial gain at 2m")
		return 1
	if ctx.volume_db_offset >= -5.5:
		push_error("Expected gain modifier to subtract ~6 dB")
		return 1
	return 0


func _test_open_mic_allows_send() -> int:
	var input_mod: VoiceInputModifier = VoiceInputModifierScript.new()
	var ctx: VoiceSendContext = VoiceSendContextScript.new()
	if not input_mod.should_send(ctx):
		push_error("Open mic should allow send")
		return 1
	return 0


func _test_ptt_blocks_send_when_not_held() -> int:
	var input_mod: VoiceInputModifier = VoiceInputModifierScript.new()
	input_mod.input_mode = VoiceInputModifier.InputMode.PUSH_TO_TALK
	var ctx: VoiceSendContext = VoiceSendContextScript.new()
	if input_mod.should_send(ctx):
		push_error("PTT should block send when key not held")
		return 1
	return 0
