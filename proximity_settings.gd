class_name ProximitySettings
extends Resource

## Master switch + nested configuration. New() ships game-ready proximity defaults.

@export var enabled: bool = true
@export var configuration: ProximityConfiguration = ProximityConfiguration.new()


func is_active() -> bool:
	return enabled and configuration != null


func _validate_property(property: Dictionary) -> void:
	if property.name == "configuration" and not enabled:
		property.usage = PROPERTY_USAGE_STORAGE
