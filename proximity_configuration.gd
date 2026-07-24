class_name ProximityConfiguration
extends Resource

## Tunable proximity chat.
##
## Between [member full_volume_buffer_radius_m] and [member max_range_m], volume
## falls from [member max_volume_db] to [member min_volume_db] using [member decay].
## Closer than the buffer stays at max; farther than max range stays at min and
## is not sent to.

enum Decay {
	## Linear interpolation in dB from max to min over distance (default).
	LINEAR_DB,
}

@export_group("Volume")
## Loudness inside the buffer radius. [code]0[/code] dB is full scale.
@export_range(-80.0, 24.0, 0.1, "suffix:dB")
var max_volume_db: float = 0.0

## Loudness at [member max_range_m] (floor before cull).
@export_range(-80.0, 0.0, 0.1, "suffix:dB")
var min_volume_db: float = -40.0

@export_group("Range")
## Inside this radius, volume stays at [member max_volume_db].
@export_range(0.0, 200.0, 0.1, "or_greater", "suffix:m")
var full_volume_buffer_radius_m: float = 8.0

## At this distance volume reaches [member min_volume_db]; farther peers are culled on send.
@export_range(0.1, 500.0, 0.1, "or_greater", "suffix:m")
var max_range_m: float = 40.0

@export_group("Falloff")
## How volume interpolates from max to min between the two radii.
@export var decay: Decay = Decay.LINEAR_DB

## Extra attenuation through walls when a [MufflingMap] is set on the session.
@export var use_wall_muffling: bool = false
