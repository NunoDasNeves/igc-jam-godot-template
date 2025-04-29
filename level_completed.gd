extends PanelContainer

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var next_level_button: Button = $MarginContainer/VBoxContainer/NextLevelButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.level_complete.connect(trigger_on_level_complete)
	next_level_button.connect("button_down", func():
		Events.relative_level_selected.emit(1)
		hide()
	)
	hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func trigger_on_level_complete(level_index: int, level_score: int) -> void:
	title_label.text = "You beat level %s" % (level_index + 1)
	score_label.text = "Score: %s" % level_score
	show()
	var timer = get_tree().create_timer(0.25)
	timer.timeout.connect(func():
		Audio.play_sfx("player_meter_full.wav", 1)
	)
