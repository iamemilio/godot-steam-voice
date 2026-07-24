class_name VoiceContextConfig
extends Resource

## Blueprint for a VoiceRuntime: binding + optional proximity (defaults to game-ready chat).

enum Binding {
	## Use VoiceMember nodes via VoiceSession.refresh_member_bindings().
	MEMBERS,
	## Runtime-owned Node3D anchors at origin (lobby-style before player heads exist).
	EPHEMERAL_CLUSTER,
	## Game registers listener/speakers on the channel itself.
	MANUAL,
}

@export var label: StringName = &""
@export var binding: Binding = Binding.MEMBERS
## Nested proximity. Default: enabled with 8m buffer / 40m range.
## Set enabled=false for lobby open mic.
@export var proximity: ProximitySettings = ProximitySettings.new()


func is_proximity_active() -> bool:
	return proximity != null and proximity.is_active()
