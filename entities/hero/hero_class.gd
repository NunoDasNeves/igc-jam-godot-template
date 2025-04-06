class_name Hero
extends Entity

@export_enum("Idle", "Exploring", "Chasing", "Action")
var hero_state: int

@onready var vision: RayCast2D = %RayCast2D

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	# If not in Idle state (0), handle other states
	if hero_state != 0:
		if hero_state == 1:
			var searching_target = hero_looking()
			if searching_target == Mimic:
				hero_state = 2
				# call function to chase here
			else:
				# move towards the player (or do something else)
				pass

		if hero_state == 3:
			# "Action" state
			# e.g., check if player is within range:
			#   if in range -> attack
			#   else move closer
			pass

func hero_looking() -> Entity:
	# RayCast2D will detect any collider it sees in its path
	var entity_seen = vision.get_collider()
	
	if entity_seen == null:
		print("Hero sees nothing.")
		return null
	else:
		print("Hero sees:", entity_seen)
		return entity_seen
