extends Node2D

@onready var walls: TileMapLayer = $WallTiles

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func coord_is_wall(coord: Vector2i) -> bool:
	var tile_data: TileData = walls.get_cell_tile_data(coord)
	if !tile_data:
		return false
	var is_wall = tile_data.get_custom_data("wall")
	return is_wall

func process_entity(entity: Entity) -> void:
	var dirs_f = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var neighbors = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var coord = walls.local_to_map(entity.position)
	var tile_center_pos = walls.map_to_local(coord)

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
			elif !coord_is_wall(coord + n_dir):
				entity.position.x = tile_center_pos.x
				if close_to_center:
					entity.position.y = tile_center_pos.y
				move_n_dir = Vector2i((tile_center_pos - entity.position).normalized())
		else:
			# same logic but for other input direction
			if close_to_center or (angle > PI/4 and angle <= PI*3/4) or (angle <= -PI/4 and angle > -PI*3/4):
				entity.position.x = tile_center_pos.x
				move_n_dir = Vector2i(dir_f)
			elif !coord_is_wall(coord + n_dir):
				entity.position.y = tile_center_pos.y
				move_n_dir = Vector2i((tile_center_pos - entity.position).normalized())

		if !move_n_dir:
			continue

		var move_dir = Vector2(move_n_dir)
		# ok finally if we're "past" the center in the move direction, and there's a wall, stop!
		# note this is a different wall check to earlier which is only for determining
		# if we should do perpendicular movement at all
		if to_center.dot(move_dir) > 0 or !coord_is_wall(coord + move_n_dir):
			entity.move_dir = move_dir

func _physics_process(delta: float) -> void:
	for entity: Entity in $Entities.get_children():
		process_entity(entity)
