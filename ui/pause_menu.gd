extends PanelContainer

@onready var main = $Main
@onready var main_resume_button = $Main/VBoxContainer/ResumeButton
@onready var main_options_button = $Main/VBoxContainer/OptionsButton

@onready var level_prev_button: Button = $Main/VBoxContainer/LevelSelectContainer/PrevButton
@onready var level_label: Label = $Main/VBoxContainer/LevelSelectContainer/LevelLabel
@onready var level_next_button: Button = $Main/VBoxContainer/LevelSelectContainer/NextButton
@onready var reset_level_button: Button = $Main/VBoxContainer/ResetLevelButton
@onready var cheating: Label = $Main/VBoxContainer/Cheating

func _ready() -> void:
	main_resume_button.connect("button_down", func (): Events.resume_clicked.emit())
	level_prev_button.connect("button_down", func():
		Events.level_changed_via_pause_menu.emit(-1)
	)
	level_next_button.connect("button_down", func():
		Events.level_changed_via_pause_menu.emit(1)
	)
	main_options_button.connect("button_down", func():
		Events.options_clicked.emit()
	)
	Events.level_changed.connect(level_select_update)
	reset_level_button.connect("button_down", func(): Events.relative_level_selected.emit(0))

	Events.level_complete.connect(func(_idx, _stats):
		level_next_button.disabled = true
		level_prev_button.disabled = true
	)
	Events.win_game.connect(func(_stats):
		level_next_button.disabled = true
		level_prev_button.disabled = true
	)
	Events.next_level_clicked.connect(func():
		level_next_button.disabled = false
		level_prev_button.disabled = false
	)

func level_select_update(index: int):
	level_next_button.disabled = false
	level_prev_button.disabled = false
	level_label.text = "Level %s" % index
	level_prev_button.disabled = index <= 0
	level_next_button.disabled = index >= Global.world.levels.size() - 1
	if Global.cheating:
		cheating.modulate.a = 1
	else:
		cheating.modulate.a = 0
