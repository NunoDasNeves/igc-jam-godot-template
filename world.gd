extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var characters = $Characters

var curr_screen: LevelScreen

func _ready() -> void:
	Events.main_char_entered_screen.connect(begin_screen)
	Events.screen_ended.connect(end_curr_screen)
	Events.character_spawned.connect(spawn_char)
	Events.vfx_spawned.connect(spawn_vfx)
	

func _physics_process(_delta: float) -> void:
	# TODO camera control
	if curr_screen:
		pass
	else:
		pass

func begin_screen(screen: LevelScreen) -> void:
	if curr_screen:
		return
	curr_screen = screen
	curr_screen.begin()

func end_curr_screen(screen: LevelScreen) -> void:
	assert(screen == curr_screen)
	curr_screen.queue_free()
	curr_screen = null

func pos_is_on_char(gpos: Vector2) -> bool:
	for character: Node2D in characters.get_children():
		if gpos.distance_squared_to(character.global_position) < 25:
			return true
	return false

func spawn_char(node: Node2D, gpos: Vector2) -> void:
	var spawn_pos = gpos
	# TODO less hacky way to make chars not spawn on top of each other
	while pos_is_on_char(spawn_pos):
		spawn_pos.x += 5
	characters.add_child(node)
	node.global_position = spawn_pos

func spawn_vfx(node: Node2D, gpos: Vector2) -> void:
	add_child(node)
	node.global_position = gpos
