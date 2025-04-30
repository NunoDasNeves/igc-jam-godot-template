class_name Hero
extends Entity

@export var num_gold_to_exit: int = 3
@export var status_sight_radius: float = 250
var status_sight_radius_squared = status_sight_radius * status_sight_radius

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
@onready var status_sight: Node2D = $StatusSight
@onready var status_sight_circle: Sprite2D = $StatusSight/Circle
@onready var status_sight_timer: Timer = $StatusSight/Timer
@onready var question_mark: Node2D = $QuestionMark

enum State { NONE, ATTACK, COLLECT, EATEN, EXIT_LEVEL, HUH }
var state: State = State.NONE

enum AIState { SEEK_ITEM, SEEK_ENEMY, SEEK_EXIT, WANDER }
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
	status_sight.hide()
	var gradient: GradientTexture2D = status_sight_circle.texture
	gradient.width = status_sight_radius * 2 + 40
	gradient.height = status_sight_radius * 2 + 40
	status_sight_timer.timeout.connect(func():
		status_sight.hide()
	)
	#assign_player_is_controlled()
	attacked.connect(attack)
	attack_node.hide()
	exclamation_point.hide()
	question_mark.hide()
	shield_poly.hide()
	set_state(State.NONE)

func stop_tweens_hide_stuff_disable_coll():
	if anim_tween:
				anim_tween.stop()
	if shield_tween:
		shield_tween.stop()
	collision_layer = 0
	collision_mask = 0
	attack_node.hide()
	exclamation_point.hide()
	question_mark.hide()
	shield_poly.hide()

func is_vulnerable():
	return state == State.COLLECT or state == State.HUH

func set_state(new_state: State) -> void:

	# cancel any state transitions goverened by tweening
	if state_tween:
		state_tween.stop()

	match new_state:
		State.NONE:
			collect_target = null
			ai_seek_target = null
		State.HUH:
			collect_target = null
			ai_seek_target = null
			question_mark.show()
			state_tween = get_tree().create_tween()
			state_tween.tween_interval(0.8)
			state_tween.tween_callback(func ():
				set_state(State.NONE)
				question_mark.hide()
			)
		State.COLLECT:
			if !collect_target:
				print ("Switch to State.COLLECT but nothing to collect!")
				return
			state_tween = get_tree().create_tween()
			state_tween.tween_interval(1)
			state_tween.tween_callback(func ():
				if !collect_target or !collect_target.get_parent():
					return
				collect_target.collect()
				do_collect(collect_target)
				if collect_target is Mimic:
					set_state(State.HUH)
					ai_seek_target = collect_target
				elif collect_target is Chest:
					pass
				elif collect_target is SightOrb:
					Audio.play_sfx("hero_collects_orb.wav")
			)
			state_tween.tween_callback(func (): set_state(State.NONE))
			if collect_target is Chest:
				Audio.play_sfx("hero_open_chest_randomizer.tres")

		State.ATTACK:
			collect_target = null
			if ai_seek_target:
				input_dir = global_position.direction_to(ai_seek_target.global_position)
			update_face_dir()
			update_visual_dir()
			attack_node.show()
			attack_swish.self_modulate.a = 0
			anim_tween = get_tree().create_tween()
			anim_tween.tween_interval(0.4)
			anim_tween.tween_callback(func ():
				Audio.play_sfx("sword_impact_randomizer.tres")
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
			stop_tweens_hide_stuff_disable_coll()
			anim_tween = get_tree().create_tween()
			anim_tween.tween_property(flip_node, "rotation_degrees", 90, 0.3)
			anim_tween.tween_interval(0.3)
			anim_tween.tween_callback(func ():
				Events.char_killed.emit(self)
				queue_free()
			)
			Audio.play_sfx("hero_swallowed_vocals.wav")
		State.EXIT_LEVEL:
			speed = 5 # walk slooowly "down" stairs
			stop_tweens_hide_stuff_disable_coll()
			anim_tween = get_tree().create_tween()
			anim_tween.tween_property(self, "modulate:a", 0, 1)
			anim_tween.tween_callback(func ():
				Events.char_killed.emit(self)
				Events.hero_escaped.emit()
				queue_free()
			)
			Audio.play_sfx("hero_finishes_level.wav", 1)

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

func can_see_hidden() -> bool:
	return status_sight_timer and status_sight_timer.time_left > 0

func do_collect(entity: Entity) -> void:
	if entity is SightOrb:
		status_sight_timer.start()
		status_sight.show()
	else:
		super(entity)

func hit(hitbox: Hitbox) -> void:
	if is_vulnerable():
		set_state(State.EATEN)
	else:
		shield_poly.show()
		shield_poly.self_modulate.a = 1
		shield_tween = get_tree().create_tween()
		shield_tween.tween_property(shield_poly, "self_modulate:a", 0, 0.7)
		shield_tween.tween_callback(func (): shield_poly.hide())
		Audio.play_sfx("hero_shields_attack.wav")

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
			if velocity:
				hero_sprite.play("move")
			else:
				hero_sprite.play("idle")
		State.HUH:
			hero_sprite.play("huh")
			input_dir = Vector2.ZERO
		State.COLLECT:
			hero_sprite.play("kneel")
			input_dir = Vector2.ZERO
		State.ATTACK:
			hero_sprite.play("attack")
			input_dir = Vector2.ZERO
		State.EATEN:
			hero_sprite.play("idle")
			input_dir = Vector2.ZERO

func get_nearest_seen_entity(coll_mask: int) -> Entity:
	var wall_coll_mask = Global.coll_layers["Wall"]
	var min_entity: Entity = null
	var min_dist_sqrd: float = INF
	for ray_cast: RayCast2D in ray_casts.get_children():
		ray_cast.collision_mask = coll_mask | wall_coll_mask
		ray_cast.force_raycast_update()
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

func get_nearest_seen_enemy() -> Entity:
	var enemy: Entity = get_nearest_seen_entity(Global.coll_layers["Player"] | Global.coll_layers["Mob"])
	if !enemy:
		return null
	# hidden mimic can't hide when status sight is on
	if can_see_hidden() and enemy.global_position.distance_squared_to(global_position) <= status_sight_radius_squared:
		return enemy
	# check if mimic is hidden and try again without player mask if so
	if enemy is Mimic:
		var mimic = enemy as Mimic
		if mimic.state == Mimic.State.HIDDEN:
			return get_nearest_seen_entity(Global.coll_layers["Mob"])
	return enemy

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

func set_ai_seek_item_or_exit():
	if gold_pocket >= num_gold_to_exit:
		ai_state = AIState.SEEK_EXIT
	else:
		ai_state = AIState.SEEK_ITEM

func ai_decide() -> void:
	# can only "decide" while in State.NORMAL
	if state != State.NONE:
		# reset the nav path so it is finished when we come back to State.NORMAL
		if !nav_agent.is_navigation_finished():
			nav_agent.target_position = global_position
		return

	# Get all the info we need to make a decision
	var chests: Array[Node2D]
	# argh gdscript... Array.assign() is needed for casting to Array[Node2D] here..
	chests.assign(get_tree().get_nodes_in_group("chest"))

	var exits: Array[Node2D]
	# argh gdscript... Array.assign() is needed for casting to Array[Node2D] here..
	exits.assign(Global.world.level.player_spawn_points)
	# prioritize chasing nearest seen enemy

	var seen_enemy = get_nearest_seen_enemy()

	# decide which AIState to use
	if seen_enemy:
		ai_seek_target = seen_enemy
		if ai_state != AIState.SEEK_ENEMY:
			Audio.play_sfx("player_spotted_by_hero.wav", 0.25, 0)
		ai_state = AIState.SEEK_ENEMY
		exclamation_point.show()
	# we're still looking for that enemy we saw earlier (until navigation is completed, see below)
	elif ai_seek_target:
		exclamation_point.show()
		ai_state = AIState.SEEK_ENEMY
	# done with collecting gold, go to exit (assuming there's an exit)
	elif exits.size() > 0 and gold_pocket >= num_gold_to_exit:
		exclamation_point.hide()
		ai_state = AIState.SEEK_EXIT
	# need moar gold
	elif chests.size() > 0:
		exclamation_point.hide()
		ai_state = AIState.SEEK_ITEM
	# no chests? just wander around to keep the player on their toes
	else:
		exclamation_point.hide()

		ai_state = AIState.WANDER

	var overlapping_bodies: Array[Node2D] = interact_or_attack_area.get_overlapping_bodies()

	# "do" the ai state
	match ai_state:
		AIState.WANDER:
			var level = Global.world.level
			var tile_coord = level.wall_tiles.local_to_map(global_position)
			var tile_center_pos = level.wall_tiles.map_to_local(tile_coord)
			var to_center: Vector2 = tile_center_pos - global_position
			var close_to_center = to_center.length_squared() < 5
			# only decide when close to center of tile (or we ain't moving already)
			if !input_dir or close_to_center:
				var snapped_dir = Vector2()
				if absf(face_dir.x) > absf(face_dir.y):
					snapped_dir.x = signf(face_dir.x)
				else:
					snapped_dir.y = signf(face_dir.y)
				assert(snapped_dir)
				var dir_i = Vector2i(snapped_dir)
				var all_dirs = [dir_i, -dir_i, Vector2i(dir_i.y, -dir_i.x), Vector2i(-dir_i.y, dir_i.x)]
				var viable_dirs = []
				for d in all_dirs:
					var next_coord = tile_coord + d
					if !level.coord_is_wall(next_coord):
						viable_dirs.append(d)
				#print(viable_dirs)
				# keep going in same direction if possible
				if viable_dirs[0] == dir_i:
					input_dir = snapped_dir
				# don't backtrack if possible
				elif viable_dirs.size() > 1 and viable_dirs[0] == -dir_i:
					viable_dirs.pop_front()
					viable_dirs.shuffle()
					input_dir = viable_dirs[0]
				else:
					viable_dirs.shuffle()
					input_dir = viable_dirs[0]

		AIState.SEEK_EXIT:
			# go to nearest exit
			var nearest_exit = Util.get_nearest_node2d(global_position, exits)
			if nearest_exit:
				if nav_agent.is_navigation_finished():
					nav_agent.target_position = nearest_exit.position
				# exit if close enough to stairs
				if nearest_exit.global_position.distance_squared_to(global_position) < 30:
					set_state(State.EXIT_LEVEL)

		AIState.SEEK_ITEM:
			# go to nearest chest - stick to this path until done
			if nav_agent.is_navigation_finished():
				var nearest_chest = Util.get_nearest_node2d(global_position, chests)
				if nearest_chest and nearest_chest is Entity:
					nav_agent.target_position = nearest_chest.position

			# collect any chest we touch
			if overlapping_bodies.size() > 0:
				for body: Node2D in overlapping_bodies:
					if try_collect(body):
						break
		AIState.SEEK_ENEMY:
			if seen_enemy: # chase latest seen enemy (seen this frame)
				nav_agent.target_position = seen_enemy.position

			elif ai_seek_target: # chase last seen enemy to last seen location
				if nav_agent.is_navigation_finished():
					ai_seek_target = null

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
