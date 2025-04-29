extends PanelContainer

@onready var play_again_button: Button = $MarginContainer/VBoxContainer/PlayAgainButton
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.win_game.connect(display)
	play_again_button.connect("button_down", func():
		Global.world.reset_game()
		hide()
	)
	hide()

func display(total_deaths: int):
	score_label.text = "Total deaths: %s" % total_deaths
	show()
