class_name SpawnPoint extends Node2D

@onready var timer: Timer = $Timer
@onready var area: Area2D = $Area2D

var coord: Vector2i
var time_secs: float

# if set, ready to actually spawn once area is clear
var _spawn_scene: PackedScene
var _spawn_parent: Node

func _ready() -> void:
	timer.start(time_secs)

func _physics_process(_delta: float) -> void:
	if _spawn_scene and can_spawn() and area.get_overlapping_bodies().size() == 0:
		_do_spawn(_spawn_scene, _spawn_parent)
		_spawn_scene = null

func _queue_spawn_asap(scene: PackedScene, parent: Node) -> void:
	_spawn_scene = scene
	_spawn_parent = parent

func _do_spawn(scene: PackedScene, entities_parent: Node) -> void:
	var node = scene.instantiate()
	entities_parent.add_child(node)
	node.global_position = global_position
	# this shoould be the case - $Level, $Entities, $World shouldn't be transformed..
	assert(node.position == node.global_position)
	# wait a bit before this spawner can be used again
	timer.start(time_secs)

func queue_spawn(scene: PackedScene, parent: Node, delay_secs: float = 0) -> void:
	if delay_secs == 0:
		timer.stop()
		_queue_spawn_asap(scene, parent)
	else:
		timer.start(delay_secs)
		for call_dict in timer.timeout.get_connections():
			timer.timeout.disconnect(call_dict.callable)
		timer.timeout.connect(func (): _queue_spawn_asap(scene, parent))

func can_spawn() -> bool:
	return timer.time_left <= 0
