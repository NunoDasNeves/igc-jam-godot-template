class_name HungerBar extends ProgressBar

signal hunger_bar_reached_100

func _on_value_changed(value: float) -> void:
	if value == 100:
		emit_signal("hunger_bar_reached_100")
		
	pass # Replace with function body.
