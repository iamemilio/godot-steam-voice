class_name VoiceContextConfig
extends Resource

## Blueprint for a [VoiceRuntime]: how peers bind, plus optional proximity.
##
## [code]VoiceContextConfig.new()[/code] includes game-ready proximity
## (8 m / 40 m). For lobby chat, set [member proximity].enabled to false.

enum Binding {
	## Use [VoiceMember] heads via [method VoiceSession.refresh_member_bindings].
	MEMBERS,
	## Runtime-owned anchors at the origin (before player heads exist).
	EPHEMERAL_CLUSTER,
	## Game registers listener/speakers on the channel itself.
	MANUAL,
}

## Optional name for logs (e.g. [code]lobby[/code], [code]game[/code]).
@export var label: StringName = &""

## How listener and speaker nodes are wired when the runtime starts.
@export var binding: Binding = Binding.MEMBERS

## Nested proximity. Default: enabled with 8 m buffer / 40 m range.
## Set [code]proximity.enabled = false[/code] for lobby open mic.
@export var proximity: ProximitySettings = ProximitySettings.new()


## True when proximity falloff should be applied.
func is_proximity_active() -> bool:
	return proximity != null and proximity.is_active()
