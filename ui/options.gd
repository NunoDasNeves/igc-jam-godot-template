extends PanelContainer

@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	back_button.connect("button_down", func(): Events.options_closed.emit())
