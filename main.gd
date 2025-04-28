class_name Main extends Node

@onready var pause_menu = $UI/PauseMenu
@onready var level_completed_menu: PanelContainer = $UI/LevelCompletedMenu
@onready var music_player: AudioStreamPlayer2D = $MusicPlayer

var looping_ambience_sfx_id: int

func _enter_tree() -> void:
	Global.main = self

func _ready() -> void:
	looping_ambience_sfx_id = Audio.play_sfx("dungeon_ambience_3.wav")
	#update_music_order()

func update_music_order():
	var stream: AudioStreamInteractive = music_player.stream
	stream.set_clip_auto_advance_next_clip(1,1)
