class_name Hitbox extends Area2D

@export var damage: float = 1
@export var hittable_factions: Array[Hurtbox.Faction] = [Hurtbox.Faction.ENEMY]

var hit_nodes: Dictionary[int, bool] = {}

func deactivate() -> void:
	monitoring = false
	monitorable = false
	hit_nodes.clear()

func _ready() -> void:
	deactivate()
	area_entered.connect(hit)

func hit(area: Area2D) -> void:
	var hurtbox: Hurtbox = area
	if !hurtbox:
		return
	# faction check
	if !hittable_factions.any(func (fac): return fac == hurtbox.faction):
		return
	# already hit check
	var hurtbox_id = hurtbox.get_instance_id()
	if hit_nodes.has(hurtbox_id):
		return

	hurtbox.hit(self)
	hit_nodes[hurtbox_id] = true

func activate(duration_secs: float) -> void:
	monitoring = true
	monitorable = true
	var timer = get_tree().create_timer(duration_secs)
	timer.timeout.connect(deactivate)
