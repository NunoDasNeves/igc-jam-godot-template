class_name Character extends CharacterBody2D

@onready var attack: Attack = $Attack
@onready var attack_2: Attack = $Attack2
@onready var hurtbox: Hurtbox = $HurtboxArea2D
@onready var hp_bar: HpBar = $HpBar
@onready var sprite: Sprite2D = $Sprite2D

@export var max_hp: float = 50
var curr_hp: float = 50

var input_dir: Vector2
var input_attack_1: bool = false
var input_attack_2: bool = false

@onready var original_self_modulate: Color = sprite.self_modulate

enum State {NONE, ATTACK, KNOCKBACK, KNOCKDOWN}
enum AIState {NONE, PASSIVE, ATTACK, REPOSITION, RECOVER}

var state: State = State.NONE
var ai_state: AIState = AIState.NONE

func _ready() -> void:
	if attack:
		attack.attack_ended.connect(func (): state = State.NONE)
	if attack_2:
		attack_2.attack_ended.connect(func (): state = State.NONE)
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = max_hp
	hurtbox.got_hit.connect(hit)

func hit(hitbox: Hitbox) -> void:
	curr_hp -= hitbox.damage
	var knockback = min(5 * hitbox.damage, 150)
	if knockback >= 80:
		set_state(State.KNOCKDOWN)
	else:
		set_state(State.KNOCKBACK)
	velocity = (global_position - hitbox.global_position).normalized() * knockback
	# flash white
	var tween = get_tree().create_tween()
	tween.tween_property($Sprite2D, "self_modulate", original_self_modulate, 0.2).from(Color.from_hsv(1,0,15))

	if hp_bar:
		hp_bar.take_damage(hitbox.damage)

func reset_sprite() -> void:
	sprite.rotation_degrees = 0
	sprite.position = Vector2(0, -12)

func set_state(new_state):
	match new_state:
		State.NONE:
			reset_sprite()
		State.ATTACK:
			reset_sprite()
			Events.main_char_attacked.emit()
		State.KNOCKBACK:
			reset_sprite()
		State.KNOCKDOWN:
			sprite.rotation_degrees = 90
			sprite.position.y = -4
	state = new_state

func decel() -> void:
	const decel: float = 2
	velocity = velocity.limit_length(max(velocity.length() - decel, 0))

func _physics_process(_delta: float) -> void:

	match state:
		State.NONE:
			velocity = input_dir * 50
			if attack and input_attack_1:
				attack.begin_attack(input_dir)
				set_state(State.ATTACK)
			elif attack and input_attack_2:
				attack_2.begin_attack(input_dir)
				set_state(State.ATTACK)
		State.ATTACK:
			decel()
		State.KNOCKBACK:
			decel()
			if velocity.length_squared() == 0:
				set_state(State.NONE)
		State.KNOCKDOWN:
			decel()
			if velocity.length_squared() == 0:
				set_state(State.NONE)

	move_and_slide()
