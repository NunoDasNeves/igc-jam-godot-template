class_name World extends Node2D

const chest_scene = preload("res://entities/chest/chest.tscn")
const sight_orb_scene = preload("res://entities/sight_orb/sight_orb.tscn")
const mimic_scene: PackedScene = preload("res://entities/mimic/mimic.tscn")
const hero_scene: PackedScene = preload("res://entities/hero/hero.tscn")
const demon_scene: PackedScene = preload("res://entities/demon/demon.tscn")

const levels_path: String = "res://levels/"
var levels: Array[PackedScene] = [
	preload(levels_path + "level_0.tscn"),
	preload(levels_path + "level_1.tscn"),
	preload(levels_path + "level_2.tscn"),
	preload(levels_path + "level_3.tscn"),
	preload(levels_path + "level_4.tscn"),
	preload(levels_path + "level_5.tscn"),
]
var curr_level_idx: int = 0
var curr_level_deaths: int = 0
var total_deaths: int = 0

@onready var entities_container: Node2D = $Entities
@onready var camera: Camera2D = $Camera2D
var level: Level

class QueuedSpawn extends RefCounted:
	var scene: PackedScene
	var spawn_point_name: String
	var delay_secs: float = 0
	var use_spawner_vis: bool = true

var spawn_queue: Array[QueuedSpawn]

func unload_curr_level():
	# we have to clear *all* the state that will affect the loaded level!
	spawn_queue.clear()
	# have to explicitly free the entities
	for entity in entities_container.get_children():
		entity.queue_free()
	if level:
		level.queue_free()

func load_level(_level_scene: PackedScene):
	unload_curr_level()
	curr_level_deaths = 0
	# ok now create the level
	level = _level_scene.instantiate()
	add_child(level)
	# level should be first child (rn because of drawing order though could use fixed Z)
	move_child(level, 0)
	var level_size_px = Vector2(level.floor_tiles.get_used_rect().size * level.floor_tiles.tile_set.tile_size)
	var center_pos = level_size_px * 0.5
	camera.global_position = center_pos
	#camera.zoom = Vector2(1.5, 1.5)

	# initial spawning
	for chest_spawner: SpawnPoint in level.chest_spawn_points:
		chest_spawner.queue_spawn(chest_scene, entities_container, 0, false)
	for sight_orb_spawner: SpawnPoint in level.sight_orb_spawn_points:
		sight_orb_spawner.queue_spawn(sight_orb_scene, entities_container, 0, false)

	queue_spawn(mimic_scene, "player")
	for _i in range(level.max_monsters):
		queue_spawn(demon_scene, "monster", 0.5)
	for _i in range(level.max_heroes):
		queue_spawn(hero_scene, "hero", 1)

func _enter_tree() -> void:
	Global.world = self

func _ready() -> void:
	Events.entity_collected.connect(trigger_collectible_respawn)
	Events.char_killed.connect(trigger_char_respawn)
	Events.char_killed.connect(count_deaths)
	Events.relative_level_selected.connect(change_level_rel)
	Events.level_complete.connect(func(_idx, _deaths): unload_curr_level())
	Events.hunger_bar_full.connect(end_level)

func _change_level_deferred(index: int):
	curr_level_idx = index
	Events.level_changed.emit(index)
	print("loading level %s" % index)
	load_level(levels[index])

func change_level(index: int):
	# this must be deferred because we could be in _ready() and not
	# everything is hooked up yet, or elsewhere in the frame..
	call_deferred("_change_level_deferred", index)

func reset_game():
	change_level(0)
	total_deaths = 0

func change_level_rel(rel_index: int):
	var new_index = clampi(curr_level_idx + rel_index, 0, levels.size() - 1)
	change_level(new_index)

func _do_end_level():
	if curr_level_idx == levels.size() - 1:
		Events.win_game.emit(total_deaths)
	else:
		Events.level_complete.emit(curr_level_idx, curr_level_deaths)
	unload_curr_level()
	Audio.play_sfx("player_meter_full.wav", 1)

func end_level():
	# TODO some kind of fade or something
	var timer = get_tree().create_timer(1)
	timer.timeout.connect(_do_end_level)

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
		var close_to_center = to_center.length_squared() < 5
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

# Queue something to spawn as soon as a spawn point is available
func queue_spawn(scene: PackedScene, spawn_point_name: String, delay_secs: float = 0, use_spawner_vis: bool = true):
	var queued_spawn = QueuedSpawn.new()
	queued_spawn.scene = scene
	queued_spawn.spawn_point_name = spawn_point_name
	queued_spawn.delay_secs = delay_secs
	queued_spawn.use_spawner_vis = use_spawner_vis
	spawn_queue.append(queued_spawn)

# Process the spawn_queue to find available spawners
func try_spawn_queued():
	var i: int = 0
	while i < spawn_queue.size():
		var succeeded: bool = false
		var queued: QueuedSpawn = spawn_queue[i]
		var spawners: Array[SpawnPoint] = level.spawn_points[queued.spawn_point_name]
		if !spawners:
			continue
		spawners = spawners.duplicate()
		spawners.shuffle()
		# find a spawner that can spawn
		while spawners.size() > 0:
			var spawner = spawners.pop_back()
			if spawner.can_spawn():
				spawner.queue_spawn(queued.scene, entities_container, queued.delay_secs, queued.use_spawner_vis)
				succeeded = true
				break
		# done with this queued spawn; take it out of the list
		if succeeded:
			#print("spawned %s" % queued.spawn_point_name)
			# swap remove
			spawn_queue[i] = spawn_queue[spawn_queue.size() - 1]
			spawn_queue.pop_back()
		else:
			i += 1

func trigger_collectible_respawn(entity: Entity) -> void:
	assert(entity.collectible)
	var scene: PackedScene
	var spawn_points: Array[SpawnPoint]
	if entity is Chest:
		scene = chest_scene
		spawn_points = level.chest_spawn_points
	elif entity is SightOrb:
		scene = sight_orb_scene
		spawn_points = level.sight_orb_spawn_points

	var coord = level.other_tiles.local_to_map(entity.position)
	var idx = spawn_points.find_custom(func (s): return s.coord == coord)
	if idx == -1:
		print("couldn't find collectible's spawner!")
		return
	var spawn_point: SpawnPoint = spawn_points[idx]
	spawn_point.queue_spawn(scene, entities_container, 10)

func count_deaths(entity: Entity):
	if entity is Mimic:
		total_deaths += 1
		curr_level_deaths += 1

func trigger_char_respawn(entity: Entity):
	if entity is Mimic:
		queue_spawn(mimic_scene, "player", 3)
	elif entity is Demon:
		queue_spawn(demon_scene, "monster", 3)
	elif entity is Hero:
		queue_spawn(hero_scene, "hero", 3)

func _physics_process(delta: float) -> void:
	for entity: Entity in entities_container.get_children():
		process_entity(entity)

	try_spawn_queued()

	if OS.is_debug_build():
		if Input.is_action_just_pressed("debug_reset_level") and Input.is_key_pressed(KEY_SHIFT):
			change_level(curr_level_idx)
		if Input.is_action_just_pressed("debug_win_level") and Input.is_key_pressed(KEY_SHIFT):
			_do_end_level()
