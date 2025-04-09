class_name Hero
extends Entity

@onready var vision: RayCast2D = %RayCast2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var flip_node: Node2D = $FlipVisuals
@onready var attack_node: Node2D = $Attack
@onready var attack_swish: Polygon2D = $Attack/Swish
@onready var hitbox: Hitbox = $Attack/Hitbox
@onready var interact_or_attack_area: Area2D = $InteractOrAttackArea

enum State { NONE, ATTACK, COLLECT }
var state: State = State.NONE

var collect_target: Entity

func _ready() -> void:
	#assign_player_is_controlled()
	attacked.connect(attack)
	interact_or_attack_area.connect("body_entered", try_collect)
	set_state(State.NONE)

func node_to_entity(node2d: Node2D) -> Entity:
	if node2d is Entity:
		return node2d as Entity
	return null

func try_collect(body: PhysicsBody2D):
	# already collecting
	if state == State.COLLECT or collect_target:
		return

	var entity: Entity = node_to_entity(body)
	if !entity:
		return

	if entity.collectible:
		collect_target = entity

func set_state(new_state: State) -> void:
	match new_state:
		State.NONE:
			collect_target = null
			attack_node.hide()
		State.COLLECT:
			if !collect_target:
				print ("Switch to State.COLLECT but nothing to collect!")
				return
			var tween = get_tree().create_tween()
			tween.tween_interval(0.5)
			tween.tween_callback(func (): collect_target.collect())
			tween.tween_interval(0.5)
			tween.tween_callback(func (): set_state(State.NONE))
		State.ATTACK:
			collect_target = null
			# TODO replace with "real" animation
			update_visual_dir()
			attack_node.show()
			attack_swish.self_modulate.a = 1
			var tween = get_tree().create_tween()
			tween.tween_interval(0.2)
			tween.tween_callback(func (): hitbox.activate())
			tween.tween_property(attack_swish, "self_modulate:a", 0, 0.1)
			tween.tween_interval(0.3)
			tween.tween_callback(func (): set_state(State.NONE))

	state = new_state

# TODO move to Util.gd or similar
func get_nearest_node2d(gpos: Vector2, nodes: Array[Node2D]) -> Node2D:
	if nodes.size() == 0:
		return null
	var min_node: Node2D = nodes[0]
	var min_dist_sqrd: float = INF

	for node: Node2D in nodes:
		var dist_srqd = gpos.distance_squared_to(node.global_position)
		if dist_srqd < min_dist_sqrd:
			min_dist_sqrd = dist_srqd
			min_node = node

	return min_node

func update_visual_dir() -> void:
	attack_node.rotation = face_dir.angle()
	if face_dir.x < 0:
		#attack_swish.scale.x = -1
		flip_node.scale.x = -1
	elif face_dir.x > 0:
		#attack_swish.scale.x = 1
		flip_node.scale.x = 1

func attack() -> void:
	match state:
		State.ATTACK:
			return
	set_state(State.ATTACK)

func _process(delta: float) -> void:
	if player_controlled:
		get_player_input()

	match state:
		State.NONE:
			update_face_dir()
			update_visual_dir()
		State.COLLECT:
			input_dir = Vector2.ZERO
		State.ATTACK:
			input_dir = Vector2.ZERO

func ai_decide() -> void:
	match state:
		State.NONE:
			if collect_target:
				set_state(State.COLLECT)
		State.COLLECT:
			pass
		State.ATTACK:
			pass

	if state == State.NONE:
		if nav_agent.is_navigation_finished():
			var chests: Array[Node2D]
			# argh gdscript
			chests.assign(get_tree().get_nodes_in_group("chest"))
			var nearest_chest = get_nearest_node2d(global_position, chests)
			if nearest_chest and nearest_chest is Entity:
				nav_agent.target_position = nearest_chest.position

		if !nav_agent.is_navigation_finished():
			var next_pos = nav_agent.get_next_path_position()
			input_dir = (next_pos - global_position).normalized()
	elif !nav_agent.is_navigation_finished():
		nav_agent.target_position = global_position

func _physics_process(delta: float) -> void:	
	if player_controlled:
		pass
	else:
		ai_decide()

	super(delta)

func hero_looking() -> Entity:
	# RayCast2D will detect any collider it sees in its path
	var entity_seen = vision.get_collider()

	if entity_seen == null:
		print("Hero sees nothing.")
		return null
	else:
		print("Hero sees:", entity_seen)
		return entity_seen
