class_name Demon
extends Entity

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var flip_node: Node2D = $FlipVisuals
@onready var demon_poly: Polygon2D = $FlipVisuals/DemonPoly
@onready var attack_node: Node2D = $Attack
@onready var attack_swish: Polygon2D = $Attack/Swish
@onready var hitbox: Hitbox = $Attack/Hitbox
@onready var interact_or_attack_area: Area2D = $InteractOrAttackArea

enum State { NONE, ATTACK, DIE }
var state: State = State.NONE

var ai_seek_target: Entity

# keep references to tweens so they can be stopped properly
# otherwise dangling references if they are running while hero is free()d
var state_tween: Tween # just does intervals and callbacks
var anim_tween: Tween

func _ready() -> void:
	#assign_player_is_controlled()
	attacked.connect(attack)
	attack_node.hide()
	set_state(State.NONE)

func node_to_entity(node2d: Node2D) -> Entity:
	if node2d is Entity:
		return node2d as Entity
	return null

func set_state(new_state: State) -> void:

	# cancel any state transitions goverened by tweening
	if state_tween:
		state_tween.stop()

	match new_state:
		State.NONE:
			pass
		State.ATTACK:
			# TODO replace with "real" animation
			update_visual_dir()
			attack_node.show()
			attack_swish.self_modulate.a = 1
			anim_tween = get_tree().create_tween()
			anim_tween.tween_interval(0.2)
			anim_tween.tween_callback(func (): hitbox.activate())
			anim_tween.tween_property(attack_swish, "self_modulate:a", 0, 0.1)
			anim_tween.tween_interval(0.3)
			anim_tween.tween_callback(func (): attack_node.hide())
			state_tween = get_tree().create_tween()
			state_tween.tween_callback(func (): set_state(State.NONE))
			anim_tween.tween_subtween(state_tween)

		State.DIE:
			collision_layer = 0
			collision_mask = 0
			demon_poly.self_modulate = Color.WHITE
			attack_node.hide()
			if anim_tween:
				anim_tween.stop()
			anim_tween = get_tree().create_tween()
			anim_tween.tween_property(flip_node, "rotation_degrees", 90, 0.3)
			anim_tween.tween_interval(0.3)
			anim_tween.tween_callback(func ():
				Events.char_killed.emit(self)
				queue_free()
			)

	state = new_state

func update_visual_dir() -> void:
	attack_node.rotation = face_dir.angle()
	if face_dir.x < 0:
		#attack_swish.scale.x = -1
		flip_node.scale.x = -1
	elif face_dir.x > 0:
		#attack_swish.scale.x = 1
		flip_node.scale.x = 1

func hit(hitbox: Hitbox) -> void:
	set_state(State.DIE)

func attack() -> void:
	if state != State.NONE:
		return
	set_state(State.ATTACK)

func _process(delta: float) -> void:
	if player_controlled:
		get_player_input()

	match state:
		State.NONE:
			update_face_dir()
			update_visual_dir()
		State.ATTACK:
			input_dir = Vector2.ZERO
		State.DIE:
			input_dir = Vector2.ZERO

func try_attack(node: Node2D) -> bool:
	if state != State.NONE or not node is Entity:
		return false

	var entity: Entity = node as Entity
	if not entity is Hero:
		return false

	set_state(State.ATTACK)
	return true

func ai_decide() -> void:
	# can only "decide" while in State.NORMAL
	if state != State.NONE:
		# reset the nav path so it is finished when we come back to State.NORMAL
		if !nav_agent.is_navigation_finished():
			nav_agent.target_position = global_position
		return

	var overlapping_bodies: Array[Node2D] = interact_or_attack_area.get_overlapping_bodies()

	if nav_agent.is_navigation_finished():
		var heroes: Array[Node2D]
		# argh gdscript... Array.assign() is needed for casting to Array[Node2D] here..
		heroes.assign(get_tree().get_nodes_in_group("hero"))
		var nearest_hero = Util.get_nearest_node2d(global_position, heroes)
		if nearest_hero and nearest_hero is Entity:
			nav_agent.target_position = nearest_hero.position
			ai_seek_target = nearest_hero
			# force nav to finish to we recompute path periodically
			var timer = get_tree().create_timer(0.1)
			timer.timeout.connect(func (): nav_agent.target_position = global_position)
	# attack any enemy we touch
	if overlapping_bodies.size() > 0:
		for body: Node2D in overlapping_bodies:
			if try_attack(body):
				break

	# follow whatever nav path we set above
	if !nav_agent.is_navigation_finished():
		var next_pos = nav_agent.get_next_path_position()
		input_dir = (next_pos - global_position).normalized()

func _physics_process(delta: float) -> void:	
	if player_controlled:
		pass
	else:
		ai_decide()

	super(delta)
