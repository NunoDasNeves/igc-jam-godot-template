extends PanelContainer

@onready var label: Label = $Label
@onready var button: Button = $Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.level_complete.connect(trigger_on_level_complete)
	button.connect("button_down", func():
		Events.relative_level_selected.emit(1)
		hide()
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func trigger_on_level_complete() -> void:
	show()
