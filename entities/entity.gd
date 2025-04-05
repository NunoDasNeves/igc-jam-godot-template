class_name Entity extends Node2D

var player_controlled: bool = true

var input_dir: Vector2
var move_dir: Vector2

func get_player_input() -> void:
	var x_in = Input.get_axis("ui_left", "ui_right")
	var y_in = Input.get_axis("ui_up", "ui_down")
	input_dir = Vector2(x_in, y_in).normalized()

func _process(_delta: float) -> void:
	if player_controlled:
		get_player_input()

func _physics_process(delta: float) -> void:
	var vel = move_dir * delta * 150
	position += vel
