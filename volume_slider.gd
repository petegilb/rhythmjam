extends HSlider

# reference: https://www.gdquest.com/tutorial/godot/audio/volume-slider/

@export var audio_bus_name := "Master"

@onready var _bus := AudioServer.get_bus_index(audio_bus_name)

func _ready() -> void:
	value = AudioServer.get_bus_volume_linear(_bus)

func _value_changed(new_value: float) -> void:
	AudioServer.set_bus_volume_linear(_bus, new_value)

#func _on_drag_ended(value_changed: bool) -> void:
	
