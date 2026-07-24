class_name ProximityConfiguration
extends Resource

## Tunable proximity chat: volume falls from max to min between buffer and max range.

enum Decay {
	## Linear interpolation in dB between max and min over distance (default).
	LINEAR_DB,
}

## Full loudness at (and inside) the buffer radius.
@export var max_volume_db: float = 0.0
## Loudness at max_range_m (and floor beyond, before cull).
@export var min_volume_db: float = -40.0
## Inside this radius, volume stays at max_volume_db.
@export var full_volume_buffer_radius_m: float = 8.0
## At this distance, volume reaches min_volume_db; farther peers are not sent to.
@export var max_range_m: float = 40.0
@export var decay: Decay = Decay.LINEAR_DB
@export var use_wall_muffling: bool = false
