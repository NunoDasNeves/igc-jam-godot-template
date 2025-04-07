class_name Hero
extends Entity

@onready var vision: RayCast2D = %RayCast2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

@export_enum("Idle", "Exploring", "Chasing", "Action")
var hero_state: int

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	# If not in Idle state (0), handle other states
	if hero_state != 0:
		if hero_state == 1:
			var searching_target = hero_looking()
			if searching_target == Mimic:
				hero_state = 2
				# call function to chase here
			else:
				# move towards the player (or do something else)
				pass

		if hero_state == 3:
			# "Action" state
			# e.g., check if player is within range:
			#   if in range -> attack
			#   else move closer
			pass

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

func _physics_process(delta: float) -> void:
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
