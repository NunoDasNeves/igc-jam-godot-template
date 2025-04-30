class_name HungerBar extends Control

@onready var bar: ProgressBar = $ProgressBar

func _ready() -> void:
	Events.hero_eaten.connect(func():
		bar.value += 1
		if bar.value == bar.max_value:
			Events.hunger_bar_full.emit()
	)

func reset(max_value: float):
	bar.max_value = max_value
	bar.value = 0
