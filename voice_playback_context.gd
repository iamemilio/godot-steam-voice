class_name VoicePlaybackContext
extends RefCounted

## Passed to receive-side rules each frame per remote speaker.

var channel: Node
var session: Node
var speaker_steam_id: int = 0
var listener_position: Vector3 = Vector3.ZERO
var speaker_position: Vector3 = Vector3.ZERO
var listener_node: Node3D
var speaker_node: Node3D
var gain_multiplier: float = 1.0
var volume_db_offset: float = 0.0
var audio_bus: String = "Master"
var transmit_flags: int = 0
