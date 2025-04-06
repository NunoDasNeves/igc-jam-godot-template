class_name Hitbox
extends Area2D

@export var damage: float = 1
@export var duration_secs: float = 0.2

# so we don't hit the same thing twice for one activation
var hit_nodes: Dictionary[int, bool] = {}

func _ready() -> void:
	deactivate()
	area_entered.connect(hit)

func deactivate() -> void:
	monitoring = false
	monitorable = false

func activate() -> void:
	monitoring = true
	monitorable = true
	hit_nodes.clear()
	var timer = get_tree().create_timer(duration_secs)
	timer.timeout.connect(deactivate)

func hit(area: Area2D) -> void:
	# TODO make this hit stuff
	pass
