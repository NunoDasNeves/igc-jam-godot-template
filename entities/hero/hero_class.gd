class_name Hero
extends Entity

@export_enum("Idle", "Exploring", "Chasing", "Action")
var hero_state: int
@onready var level: Level = %Level

@onready var vision: RayCast2D = %RayCast2D

signal _looking_for_chest()

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	match hero_state:
		0:  # Idle
			navigation_agent_2d.set_target_position(self.position)
			hero_looking()
			print("State: Idle - Looking for hero")
		
		1:  # Exploring
			var searching_target = hero_looking()
			if searching_target and searching_target is Mimic:
				hero_state = 2  # switch to Chasing
			else:
				pass
		
		2:  # Chasing
			pass
		
		3:  # Action
			pass


func hero_looking() -> Entity:
	var entity_seen = vision.get_collider()

	if entity_seen == null:
		print("Hero sees nothing.")

		if hero_state != 1:
			hero_state = 1
			print("Hero state changed to Exploring (1)")
		else:
			var timer = Timer.new()
			timer.wait_time = 2.0
			timer.one_shot = true
			add_child(timer)
			timer.start()
			timer.timeout.connect(_on_timer_timeout)

			print(hero_state)

			pass

		return null
	else:
		print("Hero sees:", entity_seen)
		return entity_seen


func _on_timer_timeout() -> void:
	print("Looking for chest signal emitted from timer!")
	on_looking_for_chest()

func on_looking_for_chest() -> void:
	var chest_position = level.coord_is_chest("chest")
	
	emit_signal("_looking_for_chest")
	
	print("suuuuper", chest_position)
