# GdUnit4 suite: demo scene smoke tests and modifier wiring.
extends GdUnitTestSuite

const SpatialAttenuationModifierScript := preload("res://modifiers/spatial_attenuation_modifier.gd")
const DEMO_SCENE := preload("res://demo/demo.tscn")


func test_demo_scene_loads() -> void:
	var instance: Node = auto_free(DEMO_SCENE.instantiate())
	assert_object(instance).is_not_null()


func test_proximity_channel_has_spatial_modifier() -> void:
	var instance: Node = auto_free(DEMO_SCENE.instantiate())
	var proximity: VoiceChannel = instance.get_node("VoiceSession/Proximity")
	assert_object(proximity).is_not_null()
	assert_int(proximity.modifiers.size()).is_greater_equal(1)
	var has_spatial := false
	for mod in proximity.modifiers:
		if mod.get_script() == SpatialAttenuationModifierScript:
			has_spatial = true
	assert_bool(has_spatial).is_true()


func test_radio_channel_has_ptt_and_roster_modifiers() -> void:
	var instance: Node = auto_free(DEMO_SCENE.instantiate())
	var radio: VoiceChannel = instance.get_node("VoiceSession/Radio")
	assert_object(radio).is_not_null()
	var has_ptt := false
	var has_roster := false
	for mod in radio.modifiers:
		if mod is VoiceInputModifier:
			has_ptt = (mod as VoiceInputModifier).input_mode == VoiceInputModifier.InputMode.PUSH_TO_TALK
		if mod is RosterModifier:
			has_roster = true
	assert_bool(has_ptt).is_true()
	assert_bool(has_roster).is_true()
