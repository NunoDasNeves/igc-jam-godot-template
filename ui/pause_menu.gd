extends PanelContainer

@onready var main = $Main
@onready var main_resume_button = $Main/VBoxContainer/ResumeButton
@onready var main_options_button = $Main/VBoxContainer/OptionsButton
@onready var options = $Options
@onready var options_back_button = $Options/VBoxContainer/BackButton

enum State {MAIN, OPTIONS}
var state: State = State.MAIN

func _ready() -> void:
	main_resume_button.connect("button_down", func (): set_paused(false))
	main_options_button.connect("button_down", func (): set_state(State.OPTIONS))
	options_back_button.connect("button_down", func(): set_state(State.MAIN))

func set_state(val: State) -> void:
	main.hide()
	options.hide()
	match val:
		State.MAIN:
			main.show()
		State.OPTIONS:
			options.show()
	state = val

func set_paused(val: bool) -> void:
	get_tree().paused = val
	visible = val

func _unhandled_key_input(event: InputEvent) -> void:
	if event.keycode == KEY_ESCAPE and event.pressed and !event.echo:
		if get_tree().paused:
			match state:
				State.MAIN:
					set_paused(false)
				State.OPTIONS:
					set_state(State.MAIN)
		else:
			set_paused(true)
