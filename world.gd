extends Node2D

@onready var _anim_sprite = $AnimatedSprite2D
@onready var _anim_player = $AnimationPlayer

@onready var _polyphony_btn = $HBoxContainer/PolyphonyButton
@onready var _solo_btn = $HBoxContainer/SoloButton

func _ready() -> void:
	_polyphony_btn.connect("button_down", func (): Audio.play_sfx("dungeon_wizard_magic_crash.wav", 0.2))
	_solo_btn.connect("button_down", func (): Audio.play_sfx("dungeon_wizard_magic_crash.wav", 0.2, 1))

func _process(_delta: float) -> void:
	_anim_sprite.play("idle-S")
	_anim_player.play("idle-S")
