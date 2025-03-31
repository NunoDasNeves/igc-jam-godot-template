extends Button

func _ready() -> void:
	connect("button_down", do_emit)

func do_emit() -> void:
	Events.nested_button_pressed.emit(get_global_mouse_position())
