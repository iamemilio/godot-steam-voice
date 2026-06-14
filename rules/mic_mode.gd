class_name MicMode
extends VoiceRule

## Controls when the mic transmits and sets walkie transmit flags on the packet envelope.

enum InputMode {
	OPEN_MIC,
	PUSH_TO_TALK,
}

@export var input_mode: InputMode = InputMode.OPEN_MIC
@export var input_action: String = "voice_push"
@export var walkie_ptt_action: String = ""
@export var open_mic_enabled: bool = true

var _ptt_held: bool = false
var _walkie_ptt_held: bool = false


func process_frame(_delta: float, _channel: Node, _session: Node) -> void:
	if input_mode == InputMode.PUSH_TO_TALK and not input_action.is_empty():
		_ptt_held = Input.is_action_pressed(input_action)
	else:
		_ptt_held = open_mic_enabled
	if not walkie_ptt_action.is_empty():
		_walkie_ptt_held = Input.is_action_pressed(walkie_ptt_action)
	else:
		_walkie_ptt_held = false


func should_send(_ctx: VoiceSendContext) -> bool:
	if input_mode == InputMode.OPEN_MIC and open_mic_enabled:
		return true
	if input_mode == InputMode.PUSH_TO_TALK and _ptt_held:
		return true
	if not walkie_ptt_action.is_empty() and _walkie_ptt_held:
		return true
	return false


func apply_transmit_flags(ctx: VoiceSendContext) -> void:
	if not walkie_ptt_action.is_empty() and _walkie_ptt_held:
		ctx.transmit_flags |= VoicePacket.FLAG_WALKIE_ACTIVE
