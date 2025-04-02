class_name Attack extends Node2D

@onready var hitbox: Hitbox = $HitboxArea2D

signal attack_ended

var attacking: bool = false

func disable() -> void:
	hide()

func _ready() -> void:
	disable()

func _physics_process(_delta: float) -> void:
	if !attacking:
		return

func begin_attack(dir: Vector2) -> void:
	show()
	# TODO flip?
	rotation = dir.angle()
	# placeholdery "animation"
	$Stick.show()
	$Whoosh.show()
	var tween = get_tree().create_tween()
	tween.tween_interval(0.2)
	tween.tween_callback(func ():
		$Whoosh.hide()
		attack_ended.emit()
	)
	tween.tween_interval(0.25)
	tween.tween_callback(func ():
		$Stick.hide()
		
	)
	hitbox.activate(0.1)
