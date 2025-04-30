class_name HungerBar extends ProgressBar

func _ready() -> void:
	Events.hero_eaten.connect(func():
		value += 1
	)
	value_changed.connect(func(val: float):
		if val == max_value:
			Events.hunger_bar_full.emit()
	)
