extends PanelContainer

@onready var main = $Main
@onready var main_resume_button = $Main/VBoxContainer/ResumeButton
@onready var main_options_button = $Main/VBoxContainer/OptionsButton
@onready var options = $Options
@onready var options_back_button = $Options/VBoxContainer/BackButton

@onready var level_prev_button: Button = $Main/VBoxContainer/LevelSelectContainer/PrevButton
@onready var level_label: Label = $Main/VBoxContainer/LevelSelectContainer/LevelLabel
@onready var level_next_button: Button = $Main/VBoxContainer/LevelSelectContainer/NextButton

@onready var sfx_label: Label = $Options/VBoxContainer/GridContainer/Label2
@onready var sfx_slider: VolumeSlider = $Options/VBoxContainer/GridContainer/HSlider2

enum State {MAIN, OPTIONS}
var state: State = State.MAIN

func _ready() -> void:
	hide()
	main_resume_button.connect("button_down", func (): set_paused(false))
	main_options_button.connect("button_down", func (): set_state(State.OPTIONS))
	options_back_button.connect("button_down", func(): set_state(State.MAIN))
	level_prev_button.connect("button_down", func(): Events.relative_level_selected.emit(-1))
	level_next_button.connect("button_down", func(): Events.relative_level_selected.emit(1))
	Events.level_changed.connect(level_select_update)
	if Global.is_web:
		sfx_label.hide()
		sfx_slider.hide()

func level_select_update(index: int):
	level_label.text = "Level %s" % index
	level_prev_button.disabled = index <= 0
	level_next_button.disabled = index >= Global.world.levels.size() - 1

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
	Audio.play_sfx("unpause_close_menu.wav")

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
