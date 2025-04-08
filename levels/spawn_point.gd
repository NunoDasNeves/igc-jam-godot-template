class_name SpawnPoint extends Node2D

@onready var delay_timer: Timer = $DelayTimer
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var area: Area2D = $Area2D

var coord: Vector2i
# delay before this spawnpoint can be used again (for hero/monster spawners)
var cooldown_secs: float = 0

# if set, ready to actually spawn once area is clear
var _spawn_scene: PackedScene
var _spawn_parent: Node

func _ready() -> void:
	cooldown_timer.stop()
	delay_timer.stop()

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
	cooldown_timer.start(cooldown_secs)

func queue_spawn(scene: PackedScene, parent: Node, delay_secs: float = 0) -> void:
	if !can_spawn():
		print ("Tried to queue_spawn() while cooldown running!")

	if delay_secs == 0:
		delay_timer.stop()
		_queue_spawn_asap(scene, parent)
	else:
		delay_timer.start(delay_secs)
		for call_dict in delay_timer.timeout.get_connections():
			delay_timer.timeout.disconnect(call_dict.callable)
		delay_timer.timeout.connect(func (): _queue_spawn_asap(scene, parent))

func can_spawn() -> bool:
	return cooldown_timer.time_left <= 0
