class_name SpawnPoint extends Node2D

var coord: Vector2i
var time_secs: float
@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.start(time_secs)

func spawn_entity(scene: PackedScene, entities_parent: Node) -> void:
	var node = scene.instantiate()
	entities_parent.add_child(node)
	node.global_position = global_position
	print("spawn at %s" % node.global_position)
	# this shoould be the case - $Level, $Entities, $World shouldn't be transformed..
	assert(node.position == node.global_position)
	# wait a bit before this spawner can be used again
	timer.start(time_secs)

func can_spawn() -> bool:
	return timer.time_left <= 0
