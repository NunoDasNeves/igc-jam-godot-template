class_name Main extends Node

@onready var pause_menu = $UI/PauseMenu
@onready var level_completed_menu: PanelContainer = $UI/LevelCompletedMenu
@onready var music_players: Array[AudioStreamPlayer] = [
	$MusicPlayer1,
	$MusicPlayer2
]
@onready var music_player = music_players[0]
var music_player_idx = 0

var music_parts: Array[AudioStream] = [
	preload("res://audio/music/intro.ogg"),
	preload("res://audio/music/a_section.ogg"),
	preload("res://audio/music/bc_sections.ogg"),
]
var music_part_idx = 0
var music_switching: bool = false
@onready var audio_output_latency = AudioServer.get_output_latency()

var looping_ambience_sfx_id: int

func _enter_tree() -> void:
	Global.main = self

func _ready() -> void:
	looping_ambience_sfx_id = Audio.play_sfx("dungeon_ambience_3.wav")
	music_player.stream = music_parts[0]
	music_player.play()
	print ("audio latency: %s" % audio_output_latency)

# do music stuff manually
func switch_music():
	#music_player.stop()
	# cycle to next player
	music_player_idx += 1
	if music_player_idx >= music_players.size():
		music_player_idx = 0
	music_player = music_players[music_player_idx]

	# cycle to next song
	music_part_idx += 1
	if music_part_idx >= music_parts.size():
		music_part_idx = 1 # skip intro
	print ("playing part %s" % music_part_idx)

	music_player.stream = music_parts[music_part_idx]
	music_player.play()
	music_switching = false
	prev_pos = -INF

var prev_pos = -INF
func process_music(delta: float):
	if music_switching:
		return
	var pos = music_player.get_playback_position() + AudioServer.get_time_since_last_mix() - audio_output_latency
	#print (pos)
	if pos < prev_pos:
		return
	prev_pos = pos
	var length = music_player.stream.get_length()
	var length_left = maxf(length - pos, 0)

	#print (length_left)
	var check_time = 0.2
	if Global.is_web:
		check_time = 0.5
	if length_left <= check_time:
		var d = 0
		if Global.is_web:
			d = audio_output_latency * 4
		var time_to_wait = maxf(length_left - audio_output_latency - d, 0)
		var timer = get_tree().create_timer(time_to_wait, true, false, false)
		timer.timeout.connect(switch_music)
		music_switching = true

func _physics_process(delta: float) -> void:
	process_music(delta)
