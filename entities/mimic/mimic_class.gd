class_name Mimic extends Entity


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assign_player_is_controlled()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if player_controlled:
		get_player_input()
