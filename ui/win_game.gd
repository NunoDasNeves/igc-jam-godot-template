extends PanelContainer

@onready var main_menu_button: Button = $MarginContainer/VBoxContainer/MainMenuButton
@onready var deaths: Label = $MarginContainer/VBoxContainer/Deaths
@onready var heroes_escaped: Label = $MarginContainer/VBoxContainer/HeroesEscaped
@onready var perfect: Label = $MarginContainer/VBoxContainer/Perfect
@onready var heroes_eaten: Label = $MarginContainer/VBoxContainer/HeroesEaten
@onready var demons_eaten: Label = $MarginContainer/VBoxContainer/DemonsEaten
@onready var cheating: Label = $MarginContainer/VBoxContainer/Cheating

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.win_game.connect(update)
	main_menu_button.connect("button_down", func():
		Events.back_to_main_menu_clicked.emit()
	)

func update(stats: Dictionary[String, int]):
	if Global.cheating:
		cheating.show()
	else:
		cheating.hide()
	deaths.text = "Total deaths: %s" % stats["deaths"]
	heroes_escaped.text = "Total heroes escaped: %s" % stats["heroes_escaped"]
	if stats["deaths"] == 0 and stats["heroes_escaped"] == 0:
		perfect.show()
	else:
		perfect.hide()
	heroes_eaten.text = "Total heroes eaten: %s" % stats["heroes_eaten"]
	demons_eaten.text = "Total demons eaten: %s" % stats["demons_eaten"]
