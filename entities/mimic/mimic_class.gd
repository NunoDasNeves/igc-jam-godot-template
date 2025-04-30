class_name Mimic extends Entity

@export var num_gold_for_glow: int = 1

# NOTE all these visuals are placeholder til we get actual art
@onready var mimic_sprite: AnimatedSprite2D = $FlipVisuals/MimicSprite
@onready var flip_node: Node2D = $FlipVisuals
@onready var swipes: Node2D = $Attack/Swipes
@onready var attack_node: Node2D = $Attack
@onready var hitbox: Hitbox = $Attack/Hitbox
@onready var inventory: Inventory = %Inventory
@onready var status_gold: StatusGold = $StatusGold
@onready var gold_glow: Node2D = $GoldGlow
@onready var status_speed: Node2D = $FlipVisuals/StatusSpeed
@onready var status_speed_timer: Timer = $FlipVisuals/StatusSpeed/Timer
@onready var status_speed_particles_2d: GPUParticles2D = $FlipVisuals/StatusSpeed/GPUParticles2D
@onready var direction_poly: Polygon2D = $DirectionPoly

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
	status_speed_timer.timeout.connect(end_status_speed)
	status_speed.hide()

func status_speed_enabled() -> bool:
	return status_speed_timer.time_left > 0

func end_status_speed():
	speed = 150
	status_speed.hide()
	status_speed_timer.stop() # in case this is called from somewhere else..

func start_status_speed():
	speed = 250
	status_speed_timer.start()
	status_speed.show()

func unhide_if_hidden():
	remove_from_group("chest")
	collectible = false

func set_state(new_state: State) -> void:
	if state_tween:
		state_tween.stop()

	match new_state:
		State.NONE:
			unhide_if_hidden()
			attack_node.hide()
			if state == State.HIDDEN:
				Audio.play_sfx("player_transform_back_to_mimic.wav")
		State.HIDDEN:
			attack_node.hide()
			Audio.play_sfx("player_transform_into_chest.wav")
			if gold_pocket >= num_gold_for_glow:
				mimic_sprite.play("chest_open")
				add_to_group("chest")
				collectible = true
			else:
				mimic_sprite.play("chest_closed")
		State.ATTACK:
			unhide_if_hidden()
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
				Audio.play_sfx("mimic_attack_randomizer.tres", 1)
			)
			state_tween.tween_interval(0.6)
			state_tween.tween_callback(func (): set_state(State.NONE))
			#anim_tween.chain().tween_subtween(state_tween)
		State.DIE:
			unhide_if_hidden()
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
			Audio.play_sfx("player_death.wav")

	state = new_state

func do_collect(entity: Entity) -> void:
	if entity is SightOrb:
		start_status_speed()
		Audio.play_sfx("player_collects_orb.wav")
	else:
		super(entity)

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
		var hero = other as Hero

		# this means we successfully hit the hero
		if hero.is_vulnerable():
			gold_pocket = 0
			status_gold.clear()
			Events.hero_eaten.emit()

func attack() -> void:
	match state:
		State.NONE, State.HIDDEN:
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

func update_face_dir():
	direction_poly.rotation = face_dir.angle()
	super()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if player_controlled:
		get_player_input()

	if gold_pocket >= num_gold_for_glow:
		gold_glow.show()
	else:
		gold_glow.hide()

	if status_speed_enabled():
		var speed = velocity.length()
		var dir = -velocity.normalized()
		var prmat: ParticleProcessMaterial = status_speed_particles_2d.process_material
		prmat.initial_velocity_min = speed
		prmat.initial_velocity_max = speed
		# particles are in FlipVisuals so gotta account for x flip
		if dir.x != 0:
			prmat.direction = Vector3(-1, dir.y, 0)
		else:
			prmat.direction = Vector3(dir.x, dir.y, 0)

	direction_poly.hide()
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
			direction_poly.show()
			input_dir = Vector2.ZERO
		State.ATTACK:
			mimic_sprite.play("attack")
			input_dir = Vector2.ZERO
		State.DIE:
			mimic_sprite.play("die")
			input_dir = Vector2.ZERO
