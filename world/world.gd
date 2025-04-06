class_name World extends Node2D

@onready var entities_container: Node2D = $Entities
@onready var level: Level = $Level
var move_dir: Vector2 = Vector2.ZERO  
func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func process_entity(entity: Entity) -> void:
	var dirs_f = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var neighbors = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var coord = level.wall_tiles.local_to_map(entity.position)
	var tile_center_pos = level.wall_tiles.map_to_local(coord)

	

func spawn_entity(spawner: Level.Spawner, scene: PackedScene) -> void:
	var node = scene.instantiate()
	if node.has_signal("_looking_for_chest"):
		node._looking_for_chest.connect(node.on_looking_for_chest)
		print(node)

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
	for child in entities_container.get_children():
		if child is Entity:
			process_entity(child)


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

func on_looking_for_chest() -> void:
	print("Spawner got the _looking_for_chest signal!")
