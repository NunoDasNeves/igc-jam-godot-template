extends MarginContainer

@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	back_button.connect("button_down", func(): Events.options_closed.emit())
	#if Global.is_web:
	#	sfx_label.hide()
	#	sfx_slider.hide()
