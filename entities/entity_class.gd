class_name Entity extends CharacterBody2D

@export var collectible: bool = false
@export var player_controlled: bool = false

signal interacted
signal attacked
# The desired move direction (from player input or AI)
var input_dir: Vector2
# The final move direction (derived from input_dir)
var move_dir: Vector2
# Last nonzero direction of input_dir
var face_dir: Vector2 = Vector2.RIGHT

var speed: float = 150.0

var status_sight: bool = false
var status_sight_timer: Timer





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

	if Input.is_action_just_pressed("Interact"):
		interacted.emit()

	if Input.is_action_just_pressed("Attack"):
		attacked.emit()

func hit(hitbox: Hitbox):
	pass

func collect():
	assert(collectible)

func do_collect(entity: Entity):
	if entity is SightOrb:
		var ss_node = find_child("StatusSight")
		if !ss_node:
			return
		if !status_sight_timer:
			status_sight_timer = Timer.new()
			status_sight_timer.wait_time = 5
			status_sight_timer.one_shot = true
			status_sight_timer.timeout.connect(func():
				ss_node.hide()
				status_sight = false
			)
			add_child(status_sight_timer)
		status_sight_timer.start()
		status_sight = true
		ss_node.show()

# called by subclasses depending on action states n whatnot
func update_face_dir() -> void:
	if !input_dir.is_zero_approx():
		if absf(input_dir.x) > absf(input_dir.y):
			face_dir = Vector2(signf(input_dir.x), 0)
		else:
			face_dir = Vector2(0, signf(input_dir.y))

func _physics_process(delta: float) -> void:
	velocity = move_dir * 150
	move_and_slide()
