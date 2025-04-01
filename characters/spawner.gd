class_name Spawner extends Marker2D

@export var spawns: Array[Spawn] = []

var should_spawn: bool = false

func _ready() -> void:
	$Polygon2D.hide()

func _physics_process(_delta: float) -> void:
	if !should_spawn:
		return
	if spawns.size() > 0:
		var spawn = spawns[0]
		if spawn.ready:
			for i in range(spawn.num):
				var node = spawn.scene.instantiate()
				Events.character_spawned.emit(node, global_position)
			spawns.pop_front()
		else:
			var timer = get_tree().create_timer(spawn.delay_secs)
			timer.timeout.connect(func(): spawn.ready = true)
	else:
		queue_free()
