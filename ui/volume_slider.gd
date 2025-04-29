extends HSlider
class_name VolumeSlider

@export var bus_name: StringName = &"Master"

@onready var bus_idx = AudioServer.get_bus_index(bus_name)

func _ready() -> void:
	value = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))

func _process(_delta: float) -> void:
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
