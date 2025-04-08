class_name Hitbox
extends Area2D

@export var damage: float = 1
@export var duration_secs: float = 0.2

# so we don't hit the same thing twice for one activation
var hit_nodes: Dictionary[int, bool] = {}

func _ready() -> void:
	deactivate()
	body_entered.connect(hit)

func deactivate() -> void:
	monitoring = false
	monitorable = false
	hide()

func activate() -> void:
	monitoring = true
	monitorable = true
	show()
	hit_nodes.clear()
	var timer = get_tree().create_timer(duration_secs)
	timer.timeout.connect(deactivate)

func hit(body: PhysicsBody2D) -> void:
	var char_body = body as CharacterBody2D
	if !char_body:
		return
	var entity = char_body as Entity
	if !entity:
		return
	var entity_id = entity.get_instance_id()
	if hit_nodes.has(entity_id):
		return

	entity.hit(self)
	hit_nodes[entity_id] = true
