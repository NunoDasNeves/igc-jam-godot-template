extends PanelContainer

@onready var play_button: Button = $MarginContainer/VBoxContainer/PlayButton
@onready var options_button: Button = $MarginContainer/VBoxContainer/OptionsButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	play_button.connect("button_down", func():
		Events.play_clicked.emit()
	)
	options_button.connect("button_down", func():
		Events.options_clicked.emit()
	)
