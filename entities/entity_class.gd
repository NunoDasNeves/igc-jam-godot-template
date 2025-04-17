class_name Entity extends CharacterBody2D

@export var collectible: bool = false
@export var player_controlled: bool = false
@export var gold_pocket: int = 0
@onready var status_gold: PackedScene = preload("res://status_gold.tscn")



#Check this later. 
signal glittery
signal interacted
signal attacked
## The desired move direction (from player input or AI)
var input_dir: Vector2
## The final move direction (derived from input_dir)
var move_dir: Vector2
## Last nonzero direction of input_dir
var face_dir: Vector2 = Vector2.RIGHT

var speed: float = 150.0

var _is_glittery: bool = false
var _status_gold: bool = false
var _status_sight: bool = false
var status_sight_timer: Timer
var status_gold_timer: Timer

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
				_status_sight = false
			)
			add_child(status_sight_timer)
		status_sight_timer.start()
		_status_sight = true
		ss_node.show()
	if entity is Chest:
		
		gold_pocket += 1
		print(gold_pocket)
		if gold_pocket == 2:
			gold_status_function_timer()
		if gold_pocket == 3:
			glittery.emit()
			

			
func get_sg_node() -> Node2D:
	var node_name := "StatusGold"
	var sg_node := find_child(node_name)

	if sg_node == null:
		var status_gold_scene := preload("res://status_gold.tscn") as PackedScene
		var status_gold_instance := status_gold_scene.instantiate()
		status_gold_instance.name = node_name
		add_child(status_gold_instance)
		status_gold_instance.show()
		return status_gold_instance
	
	return sg_node

func gold_status_function_timer() -> void:
	var sg_node: Node2D = get_sg_node()
	print(sg_node, "gold_status_function_timer")
		
	if !status_gold_timer:
		print(gold_pocket, "Timer")
		status_gold_timer = Timer.new()
		status_gold_timer.wait_time = 2
		status_gold_timer.one_shot = true
		status_gold_timer.timeout.connect(func():
			sg_node.hide()
			_status_gold = false
		)
		add_child(status_gold_timer)
	status_gold_timer.start()
	_status_gold = true
	sg_node.show()


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
