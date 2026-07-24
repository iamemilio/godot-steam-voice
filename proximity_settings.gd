class_name ProximitySettings
extends Resource

## Master switch for distance-based voice.
##
## [code]ProximitySettings.new()[/code] ships with [member enabled] true and a
## game-ready [member configuration] (8 m buffer / 40 m range). Set
## [member enabled] false for lobby-style open mic with no distance falloff.

## When false, the runtime uses a global open-mic channel and ignores configuration.
@export var enabled: bool = true

## Distance / volume tunables. Hidden in the Inspector while [member enabled] is false.
@export var configuration: ProximityConfiguration = ProximityConfiguration.new()


## True when proximity should drive the channel (enabled and configuration present).
func is_active() -> bool:
	return enabled and configuration != null


func _validate_property(property: Dictionary) -> void:
	if property.name == "configuration" and not enabled:
		property.usage = PROPERTY_USAGE_STORAGE
