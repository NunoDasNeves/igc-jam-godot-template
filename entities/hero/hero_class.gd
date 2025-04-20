class_name Hero
extends Entity

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var flip_node: Node2D = $FlipVisuals
@onready var shield_poly: Polygon2D = $FlipVisuals/ShieldPoly
@onready var hero_sprite: AnimatedSprite2D = $FlipVisuals/HeroSprite
@onready var attack_node: Node2D = $Attack
@onready var attack_swish: Polygon2D = $Attack/Swish
@onready var hitbox: Hitbox = $Attack/Hitbox
@onready var interact_or_attack_area: Area2D = $InteractOrAttackArea
@onready var ray_casts: Node2D = $RayCasts
@onready var exclamation_point: Node2D = $ExclamationPoint

enum State { NONE, ATTACK, COLLECT, EATEN }
var state: State = State.NONE

enum AIState { SEEK_ITEM, SEEK_ENEMY }
var ai_state: AIState = AIState.SEEK_ITEM
var ai_seek_target: Entity

# entity currently being collected
var collect_target: Entity

# keep references to tweens so they can be stopped properly
# otherwise dangling references if they are running while hero is free()d
var state_tween: Tween # just does intervals and callbacks
var anim_tween: Tween
var shield_tween: Tween

func _ready() -> void:
	#assign_player_is_controlled()
	attacked.connect(attack)
	attack_node.hide()
	exclamation_point.hide()
	shield_poly.hide()
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
			collect_target = null
			ai_seek_target = null
		State.COLLECT:
			if !collect_target:
				print ("Switch to State.COLLECT but nothing to collect!")
				return
			state_tween = get_tree().create_tween()
			state_tween.tween_interval(1)
			state_tween.tween_callback(func ():
				collect_target.collect()
				do_collect(collect_target)
				if collect_target is Mimic:
					set_state(State.NONE)
					ai_seek_target = collect_target
			)
			state_tween.tween_callback(func (): set_state(State.NONE))

		State.ATTACK:
			collect_target = null
			# TODO replace with "real" animation
			update_visual_dir()
			attack_node.show()
			attack_swish.self_modulate.a = 0
			anim_tween = get_tree().create_tween()
			anim_tween.tween_interval(0.4)
			anim_tween.tween_callback(func ():
				hitbox.activate()
				attack_swish.self_modulate.a = 1
			)
			anim_tween.tween_property(attack_swish, "self_modulate:a", 0, 0.2)
			anim_tween.tween_interval(0.6)
			anim_tween.tween_callback(func (): attack_node.hide())
			state_tween = get_tree().create_tween()
			state_tween.tween_callback(func (): set_state(State.NONE))
			anim_tween.tween_subtween(state_tween)

		State.EATEN:
			collision_layer = 0
			collision_mask = 0
			attack_node.hide()
			exclamation_point.hide()
			shield_poly.hide()
			if anim_tween:
				anim_tween.stop()
			if shield_tween:
				shield_tween.stop()
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
	ray_casts.rotation = face_dir.angle()
	if face_dir.x < 0:
		#attack_swish.scale.x = -1
		flip_node.scale.x = -1
	elif face_dir.x > 0:
		#attack_swish.scale.x = 1
		flip_node.scale.x = 1

func hit(hitbox: Hitbox) -> void:
	if state == State.COLLECT:
		set_state(State.EATEN)
	else:
		shield_poly.show()
		shield_poly.self_modulate.a = 1
		shield_tween = get_tree().create_tween()
		shield_tween.tween_property(shield_poly, "self_modulate:a", 0, 0.7)
		shield_tween.tween_callback(func (): shield_poly.hide())

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
			if input_dir:
				hero_sprite.play("move")
			else:
				hero_sprite.play("idle")
		State.COLLECT:
			hero_sprite.play("kneel")
			input_dir = Vector2.ZERO
		State.ATTACK:
			hero_sprite.play("attack")
			input_dir = Vector2.ZERO
		State.EATEN:
			hero_sprite.play("idle")
			input_dir = Vector2.ZERO

func get_nearest_seen_entity() -> Entity:
	var min_entity: Entity = null
	var min_dist_sqrd: float = INF
	for ray_cast: RayCast2D in ray_casts.get_children():
		if ray_cast.is_colliding():
			var obj = ray_cast.get_collider()
			if not obj is Entity:
				continue
			var entity: Entity = obj as Entity
			var dist_sqrd = global_position.distance_squared_to(entity.global_position)
			if dist_sqrd < min_dist_sqrd:
				min_entity = entity
				min_dist_sqrd = dist_sqrd

	return min_entity

func try_collect(node: Node2D) -> bool:
	if state != State.NONE or not node is Entity:
		return false

	var entity: Entity = node as Entity
	if !entity.collectible:
		return false

	collect_target = entity
	set_state(State.COLLECT)
	return true

func try_attack(node: Node2D) -> bool:
	if state != State.NONE or not node is Entity:
		return false

	var entity: Entity = node as Entity
	# TODO check for any enemy, not just Mimic
	if not (entity is Mimic or entity is Demon):
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

	# prioritize chasing nearest seen enemy
	var seen_enemy = get_nearest_seen_entity()
	if seen_enemy:
		ai_seek_target = seen_enemy
		ai_state = AIState.SEEK_ENEMY

	var overlapping_bodies: Array[Node2D] = interact_or_attack_area.get_overlapping_bodies()

	match ai_state:
		AIState.SEEK_ITEM:
			exclamation_point.hide()
			# go to nearest chest - stick to this path until done
			if nav_agent.is_navigation_finished():
				var chests: Array[Node2D]
				# argh gdscript... Array.assign() is needed for casting to Array[Node2D] here..
				chests.assign(get_tree().get_nodes_in_group("chest"))
				var nearest_chest = Util.get_nearest_node2d(global_position, chests)
				if nearest_chest and nearest_chest is Entity:
					nav_agent.target_position = nearest_chest.position
			# collect any chest we touch
			if overlapping_bodies.size() > 0:
				for body: Node2D in overlapping_bodies:
					if try_collect(body):
						break
		AIState.SEEK_ENEMY:
			exclamation_point.show()
			if seen_enemy: # chase latest seen enemy (seen this frame)
				nav_agent.target_position = seen_enemy.position

			elif ai_seek_target: # chast last seen enemy to last seen location
				if nav_agent.is_navigation_finished():
					ai_seek_target = null

			else: # reset back to seeking items
				ai_state = AIState.SEEK_ITEM

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
