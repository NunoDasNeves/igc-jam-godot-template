extends CharacterBody2D

var in_dir: Vector2

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func _physics_process(_delta: float) -> void:
	velocity = in_dir * 50
	move_and_slide()
