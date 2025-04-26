class_name Spawner extends Entity

@onready var poly_container: Node2D = $PolyContainer
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D

var entity_to_spawn: Entity
var entity_container: Node2D

static func create(entity_node: Entity, container_node: Node2D, gpos: Vector2):
	var ret = preload("res://entities/spawner/spawner.tscn").instantiate()
	ret.entity_to_spawn = entity_node
	ret.entity_container = container_node
	container_node.add_child(ret)
	ret.global_position = gpos

func _ready() -> void:
	if entity_to_spawn.spawn_sound:
		Audio.play_stream(Audio.sfx_player, entity_to_spawn.spawn_sound)
	var particles_timer = get_tree().create_timer(0.1)
	particles_timer.timeout.connect(func(): gpu_particles_2d.restart())
	var tween = get_tree().create_tween()
	tween.tween_property(poly_container, "scale", Vector2(1,1), 0.3)
	tween.tween_callback(do_spawn)
	tween.tween_property(self, "modulate:a", 0, 0.5)
	tween.tween_callback(queue_free)

func do_spawn():
	entity_container.add_child(entity_to_spawn)
	entity_to_spawn.global_position = global_position
	# this shoould be the case - $Level, $Entities, $World shouldn't be transformed..
	assert(entity_to_spawn.position == entity_to_spawn.global_position)
