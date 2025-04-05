class_name Character extends CharacterBody2D

@export var max_hp: float = 50

enum Faction {PLAYER,ENEMY}
@export var faction = Faction.PLAYER

@onready var attack: Attack = $Attack
@onready var attack_2: Attack = $Attack2
@onready var hurtbox: Hurtbox = $HurtboxArea2D
@onready var hp_bar: HpBar = $HpBar
@onready var sprite: Sprite2D = $Sprite2D
@onready var original_self_modulate: Color = sprite.self_modulate
@onready var curr_hp: float = max_hp

signal died

var input_dir: Vector2
var input_attack_1: bool = false
var input_attack_2: bool = false

enum State {NONE, ATTACK, KNOCKBACK, KNOCKDOWN, DEAD}
enum AIState {NONE, PASSIVE, ATTACK, REPOSITION, RECOVER}

var state: State = State.NONE
var ai_state: AIState = AIState.NONE

var knockdown_timer: SceneTreeTimer
var dead_timer: SceneTreeTimer

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
	# just make sure not already dead lel
	if state == State.DEAD:
		return

	curr_hp -= hitbox.damage

	if curr_hp <= 0:
		set_state(State.DEAD)
	elif hitbox.knocks_down:
		set_state(State.KNOCKDOWN)
	else:
		set_state(State.KNOCKBACK)

	velocity = (global_position - hitbox.global_position).normalized() * hitbox.knockback
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
			# lie down
			sprite.rotation_degrees = 90
			sprite.position.y = -4
			knockdown_timer = get_tree().create_timer(2)

		State.DEAD:
			# lie down
			sprite.rotation_degrees = 90
			sprite.position.y = -4
			# destroy after time
			dead_timer = get_tree().create_timer(2)
			var tween = get_tree().create_tween()
			# fade
			tween.tween_interval(1)
			tween.tween_property(sprite, "self_modulate:a", 0, 1)
			if hp_bar:
				hp_bar.hide()
			# turn off collision and hurtbox
			if hurtbox:
				hurtbox.collision_layer = 0
				hurtbox.collision_mask = 0
			collision_layer = 0
			collision_mask = 0

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
			if !knockdown_timer or knockdown_timer.time_left <= 0:
				set_state(State.NONE)

		State.DEAD:
			decel()
			if !dead_timer or dead_timer.time_left <= 0:
				died.emit()
				queue_free()

	move_and_slide()
