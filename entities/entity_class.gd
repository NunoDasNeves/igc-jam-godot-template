class_name Entity extends Node2D

var player_controlled: bool = false

var input_dir: Vector2
var move_dir: Vector2

func get_player_input() -> void:
	var x_in = Input.get_axis("Left", "Right")
	var y_in = Input.get_axis("Up", "Down")
	input_dir = Vector2(x_in, y_in).normalized()

func assign_player_is_controlled() -> void:
	if player_controlled == false:
		player_controlled = true
	else:
		print("Error player_controlled already is ",player_controlled)



func _physics_process(delta: float) -> void:
	var vel = move_dir * delta * 150
	position += vel
