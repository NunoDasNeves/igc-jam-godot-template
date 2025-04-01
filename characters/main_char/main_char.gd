extends CharacterBody2D

@onready var attack: Attack = $Attack
@onready var hurtbox: Hurtbox = $HurtboxArea2D

var input_dir: Vector2
var input_attack: bool = false

var hp: float = 50

enum State {NONE, ATTACK}

var state: State = State.NONE

func _ready() -> void:
	attack.attack_ended.connect(func (): state = State.NONE)
	hurtbox.got_hit.connect(hit)

func hit(damage: float) -> void:
	hp -= damage
	

func _process(_delta: float) -> void:
	input_dir = Vector2(0, 0)
	if Input.is_action_pressed("ui_right"):
		input_dir.x = 1
	elif Input.is_action_pressed("ui_left"):
		input_dir.x = -1
	if Input.is_action_pressed("ui_up"):
		input_dir.y = -1
	elif Input.is_action_pressed("ui_down"):
		input_dir.y = 1

	input_dir = input_dir.normalized()

	input_attack = false
	if Input.is_action_pressed("ui_select"):
		input_attack = true

func set_state(new_state):
	match new_state:
		State.NONE:
			pass
		State.ATTACK:
			Events.main_char_attacked.emit()
			attack.begin_attack(input_dir)
	state = new_state

func _physics_process(_delta: float) -> void:
	velocity = input_dir * 50
	move_and_slide()

	match state:
		State.NONE:
			if input_attack:
				set_state(State.ATTACK)
		State.ATTACK:
			pass
