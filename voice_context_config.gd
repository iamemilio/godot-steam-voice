class_name VoiceContextConfig
extends Resource

## Blueprint for a VoiceRuntime: channel tuning + how listeners/speakers are bound.

enum Binding {
	## Use VoiceMember nodes via VoiceSession.refresh_member_bindings().
	MEMBERS,
	## Runtime-owned Node3D anchors at origin (everyone in range for large far_silent_m).
	EPHEMERAL_CLUSTER,
	## Game registers listener/speakers on the channel itself.
	MANUAL,
}

@export var label: StringName = &""
@export var channel_preset: VoiceChannel.Preset = VoiceChannel.Preset.PROXIMITY
@export var near_full_volume_m: float = 5.0
@export var far_silent_m: float = 30.0
@export var use_wall_muffling: bool = false
@export var binding: Binding = Binding.MEMBERS
