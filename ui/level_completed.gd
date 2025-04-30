extends PanelContainer

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var next_level_button: Button = $MarginContainer/VBoxContainer/NextLevelButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.level_complete.connect(update)
	next_level_button.connect("button_down", func():
		Events.next_level_clicked.emit()
	)

func update(level_index: int, deaths: int) -> void:
	title_label.text = "You beat level %s" % (level_index + 1)
	score_label.text = "Deaths: %s" % deaths
