class_name Entity
extends CharacterBody2D

@export var player_controlled: bool = false
@export var speed: float = 100.0
@export var entity_sees_player: bool = false
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var level: Level = %Level




@export_enum("Left", "Right", "Up", "Down")

var facing_direction: int

var input_dir: Vector2 = Vector2.ZERO
var move_dir: Vector2 = Vector2.ZERO 

func _physics_process(delta: float) -> void:
	if player_controlled:
		get_player_input()

	velocity = input_dir * speed
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		if collision.get_collider() is TileMap:
			print("Collided with tilemap!")

	if player_controlled == false:
		pass # function entety logic. 

func get_player_input() -> void:
	var x_in = Input.get_axis("Left", "Right")
	var y_in = Input.get_axis("Up", "Down")
	var input_vec = Vector2(x_in, y_in)

	if abs(x_in) > abs(y_in):
		if x_in < 0:
			facing_direction = 0  # Left
		else:
			facing_direction = 1  # Right
	else:
		if y_in < 0:
			facing_direction = 2  # Up
		else:
			facing_direction = 3  # Down
			
	input_dir = input_vec.normalized()

func assign_player_is_controlled() -> void:
	if not player_controlled:
		player_controlled = true
	else:
		print("Error: player_controlled is already", player_controlled)

func get_target() -> void:
	if entity_sees_player == true :
		pass # grabs player position. 
	else:
		
		pass #function that gets chest position. 
	pass 

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	pass # Replace with function body.
