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
	tween.tween_interval(0.3)
	tween.tween_callback(func (): $Whoosh.hide())
	tween.tween_interval(0.4)
	tween.tween_callback(func ():
		$Stick.hide()
		attack_ended.emit()
	)
	hitbox.activate(0.2)
