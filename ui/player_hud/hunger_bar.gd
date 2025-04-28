class_name HungerBar extends ProgressBar

signal hunger_bar_reached_100

func _on_value_changed(value: float) -> void:
	if value == max_value:
		emit_signal("hunger_bar_reached_100")
		Events.level_complete.emit()
	pass # Replace with function body.
