class_name TestSpatialAttenuation
extends RefCounted

const SpatialAttenuationScript := preload("res://spatial_attenuation.gd")


func run() -> int:
	var failures := 0
	failures += _test_full_volume_inside_radius()
	failures += _test_silent_beyond_radius()
	failures += _test_mid_range()
	return failures


func _test_full_volume_inside_radius() -> int:
	var gain := SpatialAttenuationScript.distance_gain(
		Vector3.ZERO,
		Vector3(2.0, 0.0, 0.0),
		3.0,
		25.0,
		-40.0
	)
	if not is_equal_approx(gain, 1.0):
		push_error("Expected full gain inside full_volume_m")
		return 1
	return 0


func _test_silent_beyond_radius() -> int:
	var gain := SpatialAttenuationScript.distance_gain(
		Vector3.ZERO,
		Vector3(30.0, 0.0, 0.0),
		3.0,
		25.0,
		-40.0
	)
	if gain >= 0.02:
		push_error("Expected near-silent gain beyond silent_m")
		return 1
	return 0


func _test_mid_range() -> int:
	var gain := SpatialAttenuationScript.distance_gain(
		Vector3.ZERO,
		Vector3(14.0, 0.0, 0.0),
		3.0,
		25.0,
		-40.0
	)
	if gain >= 1.0 or gain <= 0.02:
		push_error("Expected partial gain between full_volume_m and silent_m")
		return 1
	return 0
