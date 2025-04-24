class_name Mimic extends Entity

# NOTE all these visuals are placeholder til we get actual art
@onready var mimic_sprite: AnimatedSprite2D = $FlipVisuals/MimicSprite
@onready var flip_node: Node2D = $FlipVisuals
@onready var swipes: Node2D = $Attack/Swipes
@onready var attack_node: Node2D = $Attack
@onready var hitbox: Hitbox = $Attack/Hitbox
@onready var inventory: Inventory = %Inventory
@onready var status_gold: StatusGold = $StatusGold
@onready var gold_glow: Node2D = $GoldGlow

enum State { NONE, HIDDEN, ATTACK, DIE }
var state: State = State.NONE

var state_tween: Tween
var anim_tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interacted.connect(interact)
	attacked.connect(attack)
	hitbox.connect("hit_entity", attack_hit)
	set_state(State.NONE)

func set_state(new_state: State) -> void:
	if state_tween:
		state_tween.stop()

	match new_state:
		State.NONE:
			attack_node.hide()
			collision_layer = 1
			remove_from_group("chest")
			collectible = false
		State.HIDDEN:
			attack_node.hide()
			collision_layer = 4
			if gold_pocket >= 3:
				mimic_sprite.play("chest_open")
				add_to_group("chest")
				collectible = true
			else:
				mimic_sprite.play("chest_closed")
		State.ATTACK:
			gold_glow.hide()
			# TODO replace with real animation
			update_visual_dir()
			attack_node.show()
			swipes.modulate.a = 0
			anim_tween = get_tree().create_tween()
			anim_tween.tween_interval(0.2)
			anim_tween.tween_callback(func(): swipes.modulate.a = 1)
			anim_tween.set_ease(Tween.EASE_IN)
			anim_tween.tween_property(swipes, "modulate:a", 0, 0.3)
			anim_tween.set_parallel(true)
			anim_tween.tween_property(flip_node, "position", flip_node.position + face_dir * 20, 0.1)
			anim_tween.set_ease(Tween.EASE_OUT)
			anim_tween.chain().tween_property(flip_node, "position", flip_node.position, 0.15)
			state_tween = get_tree().create_tween()
			state_tween.tween_interval(0.2)
			state_tween.tween_callback(func ():
				hitbox.activate()
				Audio.play_sfx("mimic_attack_randomizer.tres")
			)
			state_tween.tween_interval(0.6)
			state_tween.tween_callback(func (): set_state(State.NONE))
			#anim_tween.chain().tween_subtween(state_tween)
		State.DIE:
			if anim_tween:
				anim_tween.stop()
			attack_node.hide()
			collision_layer = 0
			anim_tween = get_tree().create_tween()
			anim_tween.tween_interval(0.5)
			anim_tween.tween_property(self, "modulate:a", 0, 0.5)
			state_tween = get_tree().create_tween()
			state_tween.tween_interval(1)
			state_tween.tween_callback(func ():
				queue_free()
			)
			Events.char_killed.emit(self)

	state = new_state

func interact() -> void:
	match state:
		State.NONE:
			set_state(State.HIDDEN)
		State.HIDDEN:
			set_state(State.NONE)

func attack_hit(other: Entity) -> void:
	if other.collectible:
		other.collect()
		inventory.pocket.append(other)
		do_collect(other)
	if other is Hero:
		gold_pocket = 0
		status_gold.clear()

func attack() -> void:
	match state:
		State.ATTACK:
			return
	# TODO remove/change when real visuals exist.
	# show green mimic again, first
	set_state(State.NONE)
	set_state(State.ATTACK)

func collect():
	set_state(State.NONE)

func hit(hitbox: Hitbox) -> void:
	# TODO?
	#Events.entity_destroyed.emit(self)
	set_state(State.DIE)

func update_visual_dir() -> void:
	attack_node.rotation = face_dir.angle()
	if face_dir.x < 0:
		flip_node.scale.x = -1
	elif face_dir.x > 0:
		flip_node.scale.x = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if player_controlled:
		get_player_input()

	if gold_pocket >= 3:
		gold_glow.show()
	else:
		gold_glow.hide()

	match state:
		State.NONE:
			update_face_dir()
			update_visual_dir()
			if mimic_sprite.animation != "attack" or !mimic_sprite.is_playing():
				if input_dir:
					mimic_sprite.play("move")
				else:
					mimic_sprite.play("idle")
		State.HIDDEN:
			update_face_dir()
			input_dir = Vector2.ZERO
		State.ATTACK:
			mimic_sprite.play("attack")
			input_dir = Vector2.ZERO
		State.DIE:
			mimic_sprite.play("die")
			input_dir = Vector2.ZERO
