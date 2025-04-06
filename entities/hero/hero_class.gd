class_name Hero
extends Entity

@export_enum("Idle", "Exploring", "Chasing", "Action")
var hero_state: int

@onready var vision: RayCast2D = %RayCast2D

signal _looking_for_chest()

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
				pass

		if hero_state == 3:
			# "Action" state
			# e.g., check if player is within range:
			#   if in range -> attack
			#   else move closer
			pass
	else:
		#Function to triger Idle Animation 
		navigation_agent_2d.set_target_position(self.position)
		hero_looking() 


func hero_looking() -> Entity:
	# RayCast2D will detect any collider it sees in its path
	var entity_seen = vision.get_collider()
	
	if entity_seen == null:
		print("Hero sees nothing.")
		var timer = Timer.new()
		timer.wait_time = 5
		timer.one_shot = true  # Runs only once; set false if you want it to repeat.
		add_child(timer)
		timer.start()
		timer.timeout.connect(_on_timer_timeout)
		print("hero_looking Timeout")
		
		if hero_state != 1:
			hero_state = 1
			print(hero_state)
		return null
	else:
		print("Hero sees:", entity_seen)
		return entity_seen

func _on_timer_timeout() -> void:
	on_looking_for_chest()
	print("Looking for chest signal emitted from timer!")

func on_looking_for_chest() -> void:
	emit_signal("_looking_for_chest")
	print("Looking for chest signal emitted")
