class_name Hero
extends Entity


@export_enum("Idle", "Exploring", "Chasing", "Action")
var hero_state: int

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var vision: RayCast2D = %RayCast2D
#@onready var level: Level = %Level

signal _looking_for_chest()

func _ready() -> void:
	hero_move.connect(_on_hero_move)

func _physics_process(delta: float) -> void:
	var next_pos = navigation_agent_2d.get_next_path_position()
	var dir = (next_pos - global_position).normalized()
	input_dir = dir
	super(delta)


func _process(_delta: float) -> void:
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
				looking_for_chest()
				pass
		
		2:  # Chasing
			pass
		
		3:  # Action
			pass

func _on_hero_move(target: Vector2) -> void:
	navigation_agent_2d.target_position = target
	print("In _on_hero_move, got target:", target)
	
	
func hero_looking() -> Entity:
	var entity_seen = vision.get_collider()

	if entity_seen == null:

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

			pass

		return null
	else:
		return entity_seen


func _on_timer_timeout() -> void:
	print("Looking for chest signal emitted from timer!")
	looking_for_chest()

func looking_for_chest() -> void:
	pass
