extends PanelContainer

@onready var main_menu_button: Button = $MarginContainer/VBoxContainer/MainMenuButton
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.win_game.connect(update)
	main_menu_button.connect("button_down", func():
		Events.back_to_main_menu_clicked.emit()
	)

func update(total_deaths: int):
	score_label.text = "Total deaths: %s" % total_deaths
