class_name HungerBar extends ProgressBar

func _on_value_changed(value: float) -> void:
	if value == max_value:
		Events.hunger_bar_full.emit()
