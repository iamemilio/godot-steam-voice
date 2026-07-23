# GdUnit4 suite: demo scene smoke tests.
extends GdUnitTestSuite

const DEMO_SCENE := preload("res://demo/demo.tscn")
const DEMO_ADVANCED_SCENE := preload("res://demo/demo_advanced.tscn")
const DEMO_RUNTIME_SCENE := preload("res://demo/demo_runtime.tscn")


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


func test_demo_runtime_has_lobby_and_game_runtimes() -> void:
	var instance: Node = auto_free(DEMO_RUNTIME_SCENE.instantiate())
	var lobby: VoiceRuntime = instance.get_node("LobbyRuntime")
	var game: VoiceRuntime = instance.get_node("GameRuntime")
	assert_object(lobby).is_not_null()
	assert_object(game).is_not_null()
	assert_object(lobby.config).is_not_null()
	assert_object(game.config).is_not_null()
	assert_int(lobby.config.binding).is_equal(VoiceContextConfig.Binding.EPHEMERAL_CLUSTER)
	assert_int(game.config.binding).is_equal(VoiceContextConfig.Binding.MEMBERS)
