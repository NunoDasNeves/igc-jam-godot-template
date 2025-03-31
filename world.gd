extends Node2D

const confetti_scene = preload("res://vfx/confetti_particles.tscn")

@onready var _anim_sprite = $AnimatedSprite2D
@onready var _anim_sprite2 = $AnimatedSprite2D2
@onready var _anim_player = $AnimationPlayer

@onready var _sfx_btn = $HBoxContainer/SFXButton
@onready var _song_1_btn = $HBoxContainer/Song1Button
@onready var _song_2_btn = $HBoxContainer/Song2Button
@onready var _stop_song_btn = $HBoxContainer/StopSongButton

func _ready() -> void:
	_sfx_btn.connect("button_down", func (): Audio.play_sfx("dungeon_wizard_ding_ding.wav", 0.2))
	_song_1_btn.connect("button_down", func(): Audio.set_music("dungeon_wizard_menu_music.wav", 0.5))
	_song_2_btn.connect("button_down", func(): Audio.set_music("sample-3s.mp3", 0.5))
	_stop_song_btn.connect("button_down", func(): Audio.stop_music())
	Events.nested_button_pressed.connect(spawn_confetti)

func _process(_delta: float) -> void:
	_anim_sprite.play("idle-S")
	_anim_sprite2.play("idle-S")
	_anim_player.play("idle-S")

func spawn_confetti(position: Vector2) -> void:
	var confetti: GPUParticles2D = confetti_scene.instantiate()
	confetti.finished.connect(func (): remove_child(confetti))
	add_child(confetti)
	confetti.global_position = position
	confetti.emitting = true
