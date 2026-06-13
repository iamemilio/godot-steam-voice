class_name VoiceInputModifier
extends VoiceModifier

enum InputMode {
	OPEN_MIC,
	PUSH_TO_TALK,
}

@export var input_mode: InputMode = InputMode.OPEN_MIC
@export var input_action: String = "voice_push"

var _ptt_held: bool = false


func process_frame(_delta: float, _channel: Node, _session: Node) -> void:
	if input_mode == InputMode.PUSH_TO_TALK and not input_action.is_empty():
		_ptt_held = Input.is_action_pressed(input_action)
	else:
		_ptt_held = true


func should_send(_ctx: VoiceSendContext) -> bool:
	if input_mode == InputMode.OPEN_MIC:
		return true
	return _ptt_held
