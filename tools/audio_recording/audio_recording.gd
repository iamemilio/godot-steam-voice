extends Control

## Dev-only WAV fixture recorder (not shipped in the addon zip). Launch via make audio-recording.

const FIXTURE_DIR := "res://tests/fixtures/audio/"
const RECORD_BUS := "AudioFixtureRecord"

@onready var _mic_list: ItemList = %MicList
@onready var _mic_level: ProgressBar = %MicLevel
@onready var _refresh_button: Button = %RefreshButton
@onready var _record_button: Button = %RecordButton
@onready var _status_label: Label = %StatusLabel
@onready var _save_panel: PanelContainer = %SavePanel
@onready var _filename_edit: LineEdit = %FilenameEdit
@onready var _preview_button: Button = %PreviewButton
@onready var _save_button: Button = %SaveButton
@onready var _file_list: ItemList = %FileList
@onready var _play_button: Button = %PlayButton
@onready var _stop_button: Button = %StopButton

var _mic_player: AudioStreamPlayer
var _playback_player: AudioStreamPlayer
var _record_effect: AudioEffectRecord
var _record_bus_idx: int = -1
var _pending_recording: AudioStreamWAV
var _recording := false
var _device_names: PackedStringArray = PackedStringArray()
var _saved_filenames: Array[String] = []
var _meter_display: float = 0.0


func _ready() -> void:
	var win := get_window()
	win.title = "Record audio fixture"
	win.size = Vector2i(480, 680)

	_save_panel.visible = false
	_mic_list.select_mode = ItemList.SELECT_SINGLE
	_file_list.select_mode = ItemList.SELECT_SINGLE
	_record_button.pressed.connect(_on_record_pressed)
	_refresh_button.pressed.connect(_refresh_mic_list)
	_mic_list.item_selected.connect(_on_mic_selected)
	_preview_button.pressed.connect(_play_pending_recording)
	_save_button.pressed.connect(_on_save_pressed)
	_play_button.pressed.connect(_play_selected_file)
	_stop_button.pressed.connect(_stop_playback)
	_file_list.item_selected.connect(_on_file_selected)
	_file_list.item_activated.connect(_on_file_activated)
	_filename_edit.text_submitted.connect(func(_text: String) -> void: _on_save_pressed())
	_setup_record_bus()
	_setup_mic_player()
	_setup_playback_player()
	_refresh_file_list()
	_refresh_mic_list()
	_update_playback_buttons()
	_set_status("Select a microphone, then press Record.")


func _process(_delta: float) -> void:
	_update_mic_level()


func _setup_record_bus() -> void:
	_record_bus_idx = AudioServer.get_bus_index(RECORD_BUS)
	if _record_bus_idx == -1:
		AudioServer.add_bus()
		_record_bus_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(_record_bus_idx, RECORD_BUS)
		AudioServer.set_bus_send(_record_bus_idx, &"")
		AudioServer.add_bus_effect(_record_bus_idx, AudioEffectRecord.new())
	_record_effect = AudioServer.get_bus_effect(_record_bus_idx, 0) as AudioEffectRecord


func _setup_mic_player() -> void:
	_mic_player = AudioStreamPlayer.new()
	_mic_player.name = "MicInput"
	_mic_player.stream = AudioStreamMicrophone.new()
	_mic_player.bus = RECORD_BUS
	add_child(_mic_player)
	_mic_player.play()


func _setup_playback_player() -> void:
	_playback_player = AudioStreamPlayer.new()
	_playback_player.name = "Playback"
	_playback_player.finished.connect(_on_playback_finished)
	add_child(_playback_player)


func _update_mic_level() -> void:
	if _record_bus_idx < 0:
		return
	var peak_db := maxf(
		AudioServer.get_bus_peak_volume_left_db(_record_bus_idx, 0),
		AudioServer.get_bus_peak_volume_right_db(_record_bus_idx, 0)
	)
	var peak_linear := db_to_linear(peak_db)
	_meter_display = lerpf(_meter_display, peak_linear, 0.35)
	if peak_linear < _meter_display:
		_meter_display = maxf(peak_linear, _meter_display * 0.88)
	_mic_level.value = clampf(_meter_display * 100.0, 0.0, 100.0)


func _refresh_mic_list() -> void:
	_mic_list.clear()
	_device_names = AudioServer.get_input_device_list()
	for device_name in _device_names:
		_mic_list.add_item(device_name)

	if _device_names.is_empty():
		_record_button.disabled = true
		_set_status("No microphone found. Check permissions and click Refresh.")
	else:
		_record_button.disabled = false
		_highlight_current_device()
		if not _recording and _pending_recording == null:
			_set_status("Select a microphone, then press Record.")


func _highlight_current_device() -> void:
	var current := AudioServer.get_input_device()
	for i in _device_names.size():
		if _device_names[i] == current:
			_mic_list.select(i)
			return
	_mic_list.select(0)
	_on_mic_selected(0)


func _on_mic_selected(index: int) -> void:
	if _recording or index < 0 or index >= _device_names.size():
		return
	AudioServer.set_input_device(_device_names[index])


func _on_record_pressed() -> void:
	if _recording:
		_stop_recording()
	else:
		_start_recording()


func _start_recording() -> void:
	if _device_names.is_empty():
		_set_status("Cannot record without a microphone.")
		return
	_stop_playback()
	_pending_recording = null
	_save_panel.visible = false
	_filename_edit.text = ""
	_record_effect.set_recording_active(true)
	_recording = true
	_record_button.text = "Stop"
	_mic_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_button.disabled = true
	_update_playback_buttons()
	_set_status("Recording… press Stop when finished.")


func _stop_recording() -> void:
	_record_effect.set_recording_active(false)
	_pending_recording = _record_effect.get_recording()
	_recording = false
	_record_button.text = "Record"
	_mic_list.mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh_button.disabled = false
	if _pending_recording == null or _pending_recording.get_length() <= 0.0:
		_pending_recording = null
		_update_playback_buttons()
		_set_status("Recording was empty. Try again and speak while recording.")
		return
	_save_panel.visible = true
	_filename_edit.grab_focus()
	var suggested := "sample_%s" % Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	_filename_edit.text = suggested
	_update_playback_buttons()
	_set_status("Recording ready (%.1fs). Preview, then Save." % _pending_recording.get_length())


func _play_pending_recording() -> void:
	if _pending_recording == null:
		_set_status("Nothing to preview — record audio first.")
		return
	_start_playback(_pending_recording, "Previewing recording…")


func _play_selected_file() -> void:
	var path := _selected_saved_path()
	if path.is_empty():
		_set_status("Select a saved recording to play.")
		return
	var stream := load(path) as AudioStream
	if stream == null:
		_set_status("Could not load %s." % path.get_file())
		return
	_start_playback(stream, "Playing %s…" % path.get_file())


func _on_file_activated(index: int) -> void:
	if index >= 0 and index < _saved_filenames.size():
		_play_selected_file()


func _on_file_selected(_index: int) -> void:
	_update_playback_buttons()


func _selected_saved_path() -> String:
	var selected := _file_list.get_selected_items()
	if selected.is_empty() or selected[0] >= _saved_filenames.size():
		return ""
	return FIXTURE_DIR + _saved_filenames[selected[0]]


func _start_playback(stream: AudioStream, status: String) -> void:
	_stop_playback()
	_playback_player.stream = stream
	_playback_player.play()
	_update_playback_buttons()
	_set_status(status)


func _stop_playback() -> void:
	if _playback_player.playing:
		_playback_player.stop()
	_on_playback_finished()


func _on_playback_finished() -> void:
	_update_playback_buttons()
	if _save_panel.visible and _pending_recording != null:
		_set_status("Preview finished. Save when ready.")
	elif not _selected_saved_path().is_empty():
		_set_status("Finished playing %s." % _selected_saved_path().get_file())
	else:
		_set_status("Playback finished.")


func _update_playback_buttons() -> void:
	var playing := _playback_player.playing
	_preview_button.disabled = _pending_recording == null or playing
	_stop_button.disabled = not playing
	var has_saved_selection := not _selected_saved_path().is_empty()
	_play_button.disabled = not has_saved_selection or playing


func _on_save_pressed() -> void:
	if _pending_recording == null:
		_set_status("Nothing to save — record audio first.")
		return
	var base_name := _sanitize_filename(_filename_edit.text.strip_edges())
	if base_name.is_empty():
		_set_status("Enter a filename using letters, numbers, dashes, or underscores.")
		return
	var path := FIXTURE_DIR + base_name + ".wav"
	if FileAccess.file_exists(path):
		_set_status("File already exists: %s — choose another name." % base_name)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FIXTURE_DIR))
	var err := _pending_recording.save_to_wav(path)
	if err != OK:
		_set_status("Save failed (%s)." % error_string(err))
		return
	_pending_recording = null
	_save_panel.visible = false
	_filename_edit.text = ""
	_refresh_file_list()
	_update_playback_buttons()
	_set_status("Saved %s.wav" % base_name)


func _refresh_file_list() -> void:
	_file_list.clear()
	_saved_filenames.clear()
	var dir := DirAccess.open(FIXTURE_DIR)
	if dir == null:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FIXTURE_DIR))
		dir = DirAccess.open(FIXTURE_DIR)
	if dir == null:
		_file_list.add_item("(could not read fixture folder)")
		_update_playback_buttons()
		return
	dir.list_dir_begin()
	var names: Array[String] = []
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.ends_with(".wav"):
			names.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	names.sort()
	if names.is_empty():
		_file_list.add_item("(no recordings yet)")
	else:
		_saved_filenames = names
		for file_name in names:
			_file_list.add_item(file_name)
	_update_playback_buttons()


func _sanitize_filename(raw: String) -> String:
	var out := ""
	for i in raw.length():
		var ch := raw[i]
		if (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9") or ch in ["-", "_"]:
			out += ch
		elif ch == " ":
			out += "_"
	return out


func _set_status(message: String) -> void:
	_status_label.text = message
