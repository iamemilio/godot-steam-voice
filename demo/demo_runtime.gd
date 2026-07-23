extends Node3D

## Demo: two Inspector-configured VoiceRuntime nodes. Toggle lobby/game/off and log level.

var _fake_peers: Array[int] = [100, 200, 300]

@onready var lobby_runtime: VoiceRuntime = $LobbyRuntime
@onready var game_runtime: VoiceRuntime = $GameRuntime
@onready var status_label: Label = $Status


func _ready() -> void:
	if OS.get_environment("STEAM_PROXIMITY_VOICE_TEST") == "1":
		return
	lobby_runtime.set_peers(_fake_peers)
	game_runtime.set_peers(_fake_peers)
	_update_status()


func _unhandled_input(event: InputEvent) -> void:
	if OS.get_environment("STEAM_PROXIMITY_VOICE_TEST") == "1":
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1:
			game_runtime.stop()
			lobby_runtime.start()
			_update_status()
		KEY_2:
			lobby_runtime.stop()
			game_runtime.start()
			_update_status()
		KEY_0:
			lobby_runtime.stop()
			game_runtime.stop()
			_update_status()
		KEY_L:
			_cycle_log_level()
			_update_status()


func _cycle_log_level() -> void:
	var next: int = (int(lobby_runtime.get_log_level()) + 1) % 3
	lobby_runtime.set_log_level(next as VoiceRuntime.LogLevel)
	game_runtime.set_log_level(next as VoiceRuntime.LogLevel)


func _update_status() -> void:
	if status_label == null:
		return
	var active := "off"
	if lobby_runtime.is_active():
		active = "lobby"
	elif game_runtime.is_active():
		active = "game"
	var level_names: Array[String] = ["OFF", "INFO", "DEBUG"]
	var level_name: String = level_names[int(lobby_runtime.get_log_level())]
	status_label.text = (
		"VoiceRuntime demo — active=%s  log=%s\n"
		+ "1 = lobby (ephemeral)  2 = game (members)  0 = stop  L = cycle log level"
	) % [active, level_name]


func _exit_tree() -> void:
	if lobby_runtime != null:
		lobby_runtime.stop()
	if game_runtime != null:
		game_runtime.stop()
