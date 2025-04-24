class_name SpawnPoint extends Node2D

@onready var delay_timer: Timer = $DelayTimer
@onready var area: Area2D = $Area2D

var coord: Vector2i

# if set, ready to actually spawn once area is clear
var _spawn_scene: PackedScene
var _spawn_parent: Node
var _show_spawner: bool = true

func _ready() -> void:
	delay_timer.stop()

func _physics_process(_delta: float) -> void:
	if _spawn_scene and delay_timer.time_left <= 0 and area.get_overlapping_bodies().size() == 0:
		_do_spawn(_spawn_scene, _spawn_parent)
		_spawn_scene = null

func _do_spawn(scene: PackedScene, entities_parent: Node) -> void:
	var node = scene.instantiate()
	if _show_spawner:
		Spawner.create(node, entities_parent, global_position)
	else:
		entities_parent.add_child(node)
		node.global_position = global_position

func queue_spawn(scene: PackedScene, parent: Node, delay_secs: float = 0, use_spawner_vis: bool = true) -> void:
	if !can_spawn():
		print ("Tried to queue_spawn() but can't use this one")

	_spawn_scene = scene
	_spawn_parent = parent
	_show_spawner = use_spawner_vis

	if delay_secs == 0:
		delay_timer.stop()
	else:
		delay_timer.start(delay_secs)

func can_spawn() -> bool:
	return _spawn_scene == null and delay_timer.time_left <= 0
