class_name Entity extends Node2D

@export var player_controlled: bool = false
@export_enum("LEFT","RIGHT", "UP", "DOWN") var vision_direction = 2
var input_dir: Vector2
var move_dir: Vector2





func get_player_input() -> void:
	var x_in = Input.get_axis("Left", "Right")
	if x_in == "Left":
		vision_direction = 0
	else:
		vision_direction = 1
	var y_in = Input.get_axis("Up", "Down")
	if y_in == "Up":
		vision_direction = 2
	else:
		vision_direction = 3
	input_dir = Vector2(x_in, y_in).normalized()

func assign_player_is_controlled() -> void:
	if player_controlled == false:
		player_controlled = true
	else:
		print("Error player_controlled already is ",player_controlled)



func _physics_process(delta: float) -> void:
	var vel = move_dir * delta * 150
	position += vel
