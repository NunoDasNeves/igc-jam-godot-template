class_name Hunger_Bar extends ProgressBar

signal hunger_meter_empty

func _on_value_changed(value: float) -> void:
	if value == 0:
		emit_signal("hunger meter empty")
