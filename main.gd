class_name Main extends Node

@onready var pause_menu = $UI/PauseMenu

func _enter_tree() -> void:
	Global.main = self
