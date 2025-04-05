extends Node2D

@onready var entities_container: Node2D = $Entities
@onready var level: Level = $Level

func _ready() -> void:
	pass

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

func spawn_entity(spawner: Level.Spawner, scene: PackedScene) -> void:
	var node = scene.instantiate()
	entities_container.add_child(node)
	var pos = level.other_tiles.map_to_local(spawner.coord)
	node.global_position = pos
	# this shoould be the case? $Level, $Entities, $World shouldn't be transformed..
	assert(node.position == node.global_position)
	# wait a bit before this spawner can be used again
	spawner.timer = get_tree().create_timer(0.5)

func spawn_entities(spawners: Array[Level.Spawner], num: int, scene:PackedScene) -> void:
	spawners.shuffle()
	while num > 0 and spawners.size() > 0:
		var spawner = spawners.pop_back()
		if spawner.timer.time_left <= 0:
			spawn_entity(spawner, scene)
			num -= 1

func _physics_process(delta: float) -> void:
	for entity: Entity in entities_container.get_children():
		process_entity(entity)

	# figure out how much stuff to spawn and get the spawners
	var num_heroes = get_tree().get_node_count_in_group("hero")
	var num_heroes_to_spawn = max(level.max_heroes - num_heroes, 0)
	if num_heroes_to_spawn > 0:
		spawn_entities(level.hero_spawners.duplicate(), num_heroes_to_spawn,  preload("res://entities/hero/hero.tscn"))

	var num_monsters = get_tree().get_node_count_in_group("monster")
	var num_monsters_to_spawn = max(level.max_monsters - num_monsters, 0)
	if num_monsters_to_spawn > 0:
		spawn_entities(level.monster_spawners.duplicate(), num_monsters_to_spawn,  preload("res://entities/mimic/mimic.tscn"))

	# kill first monster in group, for testing spawning
	if Input.is_key_pressed(KEY_K):
		var monsters = get_tree().get_nodes_in_group("monster")
		if monsters.size() > 0:
			monsters[0].queue_free()
