# GdUnit4 suite: demo scene smoke tests.
extends GdUnitTestSuite

const DEMO_SCENE := preload("res://demo/demo.tscn")
const DEMO_ADVANCED_SCENE := preload("res://demo/demo_advanced.tscn")


func test_demo_scene_loads() -> void:
	var instance: Node = auto_free(DEMO_SCENE.instantiate())
	assert_object(instance).is_not_null()


func test_demo_has_single_voice_channel_with_proximity_preset() -> void:
	var instance: Node = auto_free(DEMO_SCENE.instantiate())
	var voice: VoiceChannel = instance.get_node("VoiceSession/Voice")
	assert_object(voice).is_not_null()
	assert_int(voice.preset).is_equal(VoiceChannel.Preset.PROXIMITY)


func test_demo_advanced_has_separate_comms_enabled() -> void:
	var instance: Node = auto_free(DEMO_ADVANCED_SCENE.instantiate())
	var session: VoiceSession = instance.get_node("VoiceSession")
	assert_bool(session.allow_separate_comms).is_true()
	assert_int(session.get_child_count()).is_greater_equal(2)
