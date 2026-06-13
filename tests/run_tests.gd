extends SceneTree

## Standalone test entry for steam_proximity_voice.
## Run from repo root:
##   godot --headless --path addons/steam_proximity_voice --script res://tests/run_tests.gd
## Or:
##   python addons/steam_proximity_voice/tools/run_tests.py

const VoiceTestEnv := preload("res://tests/test_env.gd")
const TestSpatialAttenuation := preload("res://tests/test_spatial_attenuation.gd")
const TestRoomGraph := preload("res://tests/test_room_graph.gd")
const TestModifierStack := preload("res://tests/test_modifier_stack.gd")
const TestVoiceIntegration := preload("res://tests/test_voice_integration.gd")


func _init() -> void:
	VoiceTestEnv.ensure_active()
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("Running steam_proximity_voice tests (offline — no Steam required)...")
	var failures := 0

	failures += TestSpatialAttenuation.new().run()
	failures += TestRoomGraph.new().run()
	failures += TestModifierStack.new().run()
	failures += TestVoiceIntegration.new().run(self)

	if failures == 0:
		print("All steam_proximity_voice tests passed.")
		quit(0)
	else:
		push_error("%d steam_proximity_voice test(s) failed." % failures)
		quit(1)
