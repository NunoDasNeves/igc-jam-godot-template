extends Node2D

const chest_scene = preload("res://entities/chest/chest.tscn")
const sight_orb_scene = preload("res://entities/sight_orb/sight_orb.tscn")

@onready var entities_container: Node2D = $Entities
@onready var level: Level = $Level

func _ready() -> void:
	Events.chest_destroyed.connect(trigger_chest_respawn)
	for chest_spawner: SpawnPoint in level.chest_spawn_points:
		chest_spawner.queue_spawn(chest_scene, entities_container)
	for sight_orb_spawner: SpawnPoint in level.sight_orb_spawn_points:
		sight_orb_spawner.queue_spawn(sight_orb_scene, entities_container)
	

func _process(_delta: float) -> void:
	pass

func process_entity(entity: Entity) -> void:
	var dirs_f = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var neighbors = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var coord = level.wall_tiles.local_to_map(entity.position)
	var tile_center_pos = level.wall_tiles.map_to_local(coord)

	entity.move_dir = Vector2.ZERO
	if entity.input_dir.x == 0 and entity.input_dir.y == 0:
		return

	for i in range(4):
		var dir_f = dirs_f[i]
		var n_dir = neighbors[i]
		# x dot y = cos(theta). If theta is >= 45 degrees then ignore
		# (probably only relevant for joystick input)
		if entity.input_dir.dot(dir_f) <= 0.707:
			continue
		var to_center: Vector2 = tile_center_pos - entity.position
		var angle = (-to_center).angle()
		var close_to_center = to_center.length_squared() < 2
		var move_n_dir: Vector2i
		# okay check axis depending on input direction
		if dir_f.x != 0:
			# close to center, or in left or right quadrant:
			# snap to y axis and move in the raw direction
			if close_to_center or (angle > -PI/4 and angle <= PI/4) or angle > PI*3/4 or angle <= -PI*3/4:
				entity.position.y = tile_center_pos.y
				if close_to_center:
					entity.position.x = tile_center_pos.x
				move_n_dir = Vector2i(dir_f)
			# in top or bottom quadrant, and the input dir isn't a wall
			# snap to x axis, and go perpendicular to get to center of square
			elif !level.coord_is_wall(coord + n_dir):
				entity.position.x = tile_center_pos.x
				if close_to_center:
					entity.position.y = tile_center_pos.y
				move_n_dir = Vector2i((tile_center_pos - entity.position).normalized())
		else:
			# same logic but for other input direction
			if close_to_center or (angle > PI/4 and angle <= PI*3/4) or (angle <= -PI/4 and angle > -PI*3/4):
				entity.position.x = tile_center_pos.x
				move_n_dir = Vector2i(dir_f)
			elif !level.coord_is_wall(coord + n_dir):
				entity.position.y = tile_center_pos.y
				move_n_dir = Vector2i((tile_center_pos - entity.position).normalized())

		if !move_n_dir:
			continue

		var move_dir = Vector2(move_n_dir)
		# ok finally if we're "past" the center in the move direction, and there's a wall, stop!
		# note this is a different wall check to earlier which is only for determining
		# if we should do perpendicular movement at all
		if to_center.dot(move_dir) > 0 or !level.coord_is_wall(coord + move_n_dir):
			entity.move_dir = move_dir

func spawn_entities(spawners: Array[SpawnPoint], num: int, scene:PackedScene) -> void:
	spawners.shuffle()
	while num > 0 and spawners.size() > 0:
		var spawner = spawners.pop_back()
		if spawner.can_spawn():
			spawner.queue_spawn(scene, entities_container)
			num -= 1

func spawn_entities_by_group_count(group_name: String, max_count: int, spawn_points: Array[SpawnPoint], scene: PackedScene):
	var curr_count = get_tree().get_node_count_in_group(group_name)
	var num_to_spawn = max(max_count - curr_count, 0)
	if num_to_spawn > 0:
		spawn_entities(spawn_points.duplicate(), num_to_spawn, scene) 

func trigger_chest_respawn(chest: Chest) -> void:
	var coord = level.other_tiles.local_to_map(chest.position)
	var idx = level.chest_spawn_points.find_custom(func (s): return s.coord == coord)
	if idx == -1:
		print("couldn't find chest's spawner!")
		return
	var spawn_point: SpawnPoint = level.chest_spawn_points[idx]
	spawn_point.queue_spawn(chest_scene, entities_container, 5)

func _physics_process(delta: float) -> void:
	for entity: Entity in entities_container.get_children():
		process_entity(entity)

	spawn_entities_by_group_count("hero", level.max_heroes, level.hero_spawn_points, preload("res://entities/hero/hero.tscn"))
	spawn_entities_by_group_count("monster", level.max_monsters, level.monster_spawn_points, preload("res://entities/mimic/mimic.tscn"))

	# kill first monster in group, for testing spawning
	if Input.is_key_pressed(KEY_K):
		var monsters = get_tree().get_nodes_in_group("monster")
		if monsters.size() > 0:
			monsters[0].queue_free()
