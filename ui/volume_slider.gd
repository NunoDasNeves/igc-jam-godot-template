extends HSlider
class_name VolumeSlider

@export var bus_name: StringName = &"Master"

@onready var bus_idx = AudioServer.get_bus_index(bus_name)
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	audio_stream_player.bus = bus_name
	value = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	value_changed.connect(set_volume)
	if bus_name == &"sfx":
		drag_ended.connect(func(_changed: bool):
			audio_stream_player.play()
		)

func set_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
