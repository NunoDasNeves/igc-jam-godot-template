extends PanelContainer

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var next_level_button: Button = $MarginContainer/VBoxContainer/NextLevelButton
@onready var deaths: Label = $MarginContainer/VBoxContainer/Deaths
@onready var heroes_escaped: Label = $MarginContainer/VBoxContainer/HeroesEscaped
@onready var perfect: Label = $MarginContainer/VBoxContainer/Perfect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.level_complete.connect(update)
	next_level_button.connect("button_down", func():
		Events.next_level_clicked.emit()
	)

func update(level_index: int, stats: Dictionary[String, int]) -> void:
	title_label.text = "You beat level %s" % (level_index + 1)
	deaths.text = "Deaths: %s" % stats["deaths"]
	heroes_escaped.text = "Heroes escaped: %s" % stats["heroes_escaped"]
	if stats["deaths"] == 0 and stats["heroes_escaped"] == 0:
		perfect.show()
	else:
		perfect.hide()
