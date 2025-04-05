extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var characters = $Characters
@onready var main_char = $Characters/MainChar

var curr_screen: LevelScreen

func _ready() -> void:
	Events.main_char_entered_screen.connect(begin_screen)
	Events.screen_ended.connect(end_curr_screen)
	Events.character_spawned.connect(spawn_char)
	Events.vfx_spawned.connect(spawn_vfx)

func _physics_process(_delta: float) -> void:
	# TODO camera control
	var v_rect = get_viewport_rect()
	camera.global_position.x = main_char.global_position.x
	if curr_screen:
		var coll_shape: CollisionShape2D = curr_screen.coll_shape
		var rect_shape: RectangleShape2D = coll_shape.shape
		camera.limit_left = coll_shape.global_position.x - rect_shape.size.x * 0.5
		camera.limit_right = coll_shape.global_position.x + rect_shape.size.x * 0.5
	else:
		camera.limit_left = -10000000
		camera.limit_right = 10000000
	

func begin_screen(screen: LevelScreen) -> void:
	if curr_screen:
		return
	print("begin screen: %s" % screen.get_instance_id())
	curr_screen = screen
	curr_screen.begin()

func end_curr_screen(screen: LevelScreen) -> void:
	assert(screen == curr_screen)
	curr_screen.queue_free()
	curr_screen = null
	print("end_curr_screen")

func pos_is_on_char(gpos: Vector2) -> bool:
	for character: Node2D in characters.get_children():
		if gpos.distance_squared_to(character.global_position) < 25:
			return true
	return false

func spawn_char(node: Node2D, gpos: Vector2) -> void:
	var character: Character = node
	if !character:
		return
	var spawn_pos = gpos
	# TODO less hacky way to make chars not spawn on top of each other
	while pos_is_on_char(spawn_pos):
		spawn_pos.x += 5
	characters.add_child(character)
	character.global_position = spawn_pos
	character.died.connect(character_died)
	# TODO check faction
	curr_screen.enemy_spawned()

func character_died() -> void:
	curr_screen.enemy_died()

func spawn_vfx(node: Node2D, gpos: Vector2) -> void:
	add_child(node)
	node.global_position = gpos
