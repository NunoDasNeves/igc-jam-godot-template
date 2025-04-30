class_name Main extends Node

@onready var pause_menu = $UI/PauseMenu
@onready var level_completed_menu: PanelContainer = $UI/LevelCompletedMenu
@onready var ambience_player: AudioStreamPlayer = $AmbiencePlayer

func _enter_tree() -> void:
	Global.main = self
