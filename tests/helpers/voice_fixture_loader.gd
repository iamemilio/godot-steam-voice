class_name VoiceFixtureLoader
extends RefCounted

## Load WAV golden fixtures from tests/fixtures/audio/ for headless playback tests.
## Reads the source .wav file directly so Godot import compression does not alter PCM.

const FIXTURES_DIR := "res://tests/fixtures/audio/"


static func load_wav(path: String) -> AudioStreamWAV:
	return load(path) as AudioStreamWAV


static func load_mono_pcm(path: String) -> Dictionary:
	var file_path := _globalize(path)
	if file_path.is_empty():
		return {}
	return _load_mono_pcm_from_file(file_path)


static func load_manifest() -> Dictionary:
	var path := "res://tests/fixtures/manifest.json"
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func get_manifest_entry(file_name: String) -> Dictionary:
	var manifest := load_manifest()
	var entries: Array = manifest.get("fixtures", [])
	for entry in entries:
		if entry is Dictionary and str(entry.get("file", "")).ends_with(file_name):
			return entry
	return {}


static func md5_mono_s16_prefix(pcm_bytes: PackedByteArray, sample_count: int) -> String:
	var byte_count := mini(pcm_bytes.size(), sample_count * 2)
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	ctx.update(pcm_bytes.slice(0, byte_count))
	return ctx.finish().hex_encode()


static func _globalize(path: String) -> String:
	if path.begins_with("res://"):
		return ProjectSettings.globalize_path(path)
	return path


static func _load_mono_pcm_from_file(file_path: String) -> Dictionary:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}
	if file.get_buffer(4).get_string_from_ascii() != "RIFF":
		return {}
	file.seek(8)
	if file.get_buffer(4).get_string_from_ascii() != "WAVE":
		return {}

	var channels := 0
	var sample_rate := 0
	var bits_per_sample := 0
	var pcm_bytes := PackedByteArray()

	while file.get_position() < file.get_length():
		var chunk_id := file.get_buffer(4).get_string_from_ascii()
		var chunk_size := file.get_32()
		match chunk_id:
			"fmt ":
				var _audio_format := file.get_16()
				channels = file.get_16()
				sample_rate = file.get_32()
				file.get_32()
				file.get_16()
				bits_per_sample = file.get_16()
				var fmt_remaining := chunk_size - 16
				if fmt_remaining > 0:
					file.seek(file.get_position() + fmt_remaining)
			"data":
				pcm_bytes = file.get_buffer(chunk_size)
				break
			_:
				file.seek(file.get_position() + chunk_size)

	if pcm_bytes.is_empty() or channels <= 0 or sample_rate <= 0 or bits_per_sample != 16:
		return {}
	if channels == 2:
		pcm_bytes = _stereo_to_mono_s16(pcm_bytes)
	elif channels != 1:
		return {}

	var samples := SteamVoiceTransport.pcm_bytes_to_mono_floats(pcm_bytes)
	return {
		"buffer": pcm_bytes,
		"samples": samples,
		"sample_rate": sample_rate,
		"duration_sec": float(samples.size()) / float(sample_rate),
	}


static func _stereo_to_mono_s16(interleaved: PackedByteArray) -> PackedByteArray:
	var frame_count := interleaved.size() / 4
	var mono := PackedByteArray()
	mono.resize(frame_count * 2)
	for i in frame_count:
		var offset := i * 4
		var left := interleaved.decode_s16(offset)
		var right := interleaved.decode_s16(offset + 2)
		mono.encode_s16(i * 2, int((left + right) / 2))
	return mono
