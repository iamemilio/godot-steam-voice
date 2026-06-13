class_name SpatialAttenuation
extends RefCounted

## Pure distance-attenuation math (linear meters → gain multiplier).


static func distance_gain(
	listener_position: Vector3,
	speaker_position: Vector3,
	full_volume_m: float,
	silent_m: float,
	min_volume_db: float
) -> float:
	var distance := listener_position.distance_to(speaker_position)
	if distance <= full_volume_m:
		return 1.0
	if silent_m <= full_volume_m:
		return db_to_linear(min_volume_db)
	if distance >= silent_m:
		return db_to_linear(min_volume_db)
	var t := (distance - full_volume_m) / (silent_m - full_volume_m)
	var db := lerpf(0.0, min_volume_db, t)
	return db_to_linear(db)


static func distance_gain_db(
	listener_position: Vector3,
	speaker_position: Vector3,
	full_volume_m: float,
	silent_m: float,
	min_volume_db: float
) -> float:
	var gain := distance_gain(
		listener_position,
		speaker_position,
		full_volume_m,
		silent_m,
		min_volume_db
	)
	return linear_to_db(maxf(gain, 0.00001))
