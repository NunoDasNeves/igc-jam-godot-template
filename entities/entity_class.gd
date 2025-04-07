class_name Entity
extends Node2D

var player_controlled: bool = false

signal interacted
signal attacked
signal hero_move

var input_dir: Vector2
var move_dir: Vector2

func _ready() -> void:
	pass
	

func get_player_input() -> void:
	# 1) Get axis input
	var x_in = Input.get_axis("Left", "Right")
	var y_in = Input.get_axis("Up", "Down")
	input_dir = Vector2(x_in, y_in).normalized()

	# 2) Check for one-shot actions
	if Input.is_action_just_pressed("Interact"):
		emit_signal("interacted")

	if Input.is_action_just_pressed("Attack"):
		emit_signal("attacked")

	if Input.is_action_just_pressed("HeroMove"):
		var target = get_global_mouse_position()
		hero_move.emit(target)
		print("Space pressed; hero_move signal emitted with target:", target)



func assign_player_is_controlled() -> void:
	if not player_controlled:
		player_controlled = true
	else:
		print("Error: player_controlled already is", player_controlled)

func hit(hitbox: Hitbox) -> void:
	# Called when something hits this entity.
	pass

func _physics_process(delta: float) -> void:
	# Call get_player_input() each frame so we continuously check for new input.
	#get_player_input()

	# If you want the entity to move with WASD or arrow keys, use "input_dir" as velocity.
	var vel = input_dir * 150 * delta
	position += vel
