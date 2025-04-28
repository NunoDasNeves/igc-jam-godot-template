class_name Entity extends CharacterBody2D

@export var collectible: bool = false
@export var player_controlled: bool = false
@export var gold_pocket: int = 0
@export var spawn_sound: AudioStream
@export var spawn_volume: float = 0.5
#Check this later. 

signal interacted
signal attacked
# The desired move direction (from player input or AI)
var input_dir: Vector2
# The final move direction (derived from input_dir)
var move_dir: Vector2
# Last nonzero direction of input_dir
var face_dir: Vector2 = Vector2.RIGHT

var speed: float = 150.0

func get_player_input() -> void:
	var x_in = Input.get_axis("Left", "Right")
	var y_in = Input.get_axis("Up", "Down")
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
	if entity is Chest:
		var sg_node: StatusGold = find_child("StatusGold")
		if !sg_node:
			return

		if gold_pocket < 3:
			sg_node.add_one()
			gold_pocket += 1

		sg_node.show_then_fade()

# called by subclasses depending on action states n whatnot
func update_face_dir() -> void:
	if !input_dir.is_zero_approx():
		if absf(input_dir.x) > absf(input_dir.y):
			face_dir = Vector2(signf(input_dir.x), 0)
		else:
			face_dir = Vector2(0, signf(input_dir.y))

func _physics_process(delta: float) -> void:
	velocity = move_dir * speed
	move_and_slide()
