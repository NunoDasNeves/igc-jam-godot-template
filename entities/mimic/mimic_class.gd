class_name Mimic extends Entity

enum State { NONE, HIDDEN }
var state: State = State.NONE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assign_player_is_controlled()
	interacted.connect(interact)
	set_state(State.NONE)

func set_state(new_state: State) -> void:
	match new_state:
		State.NONE:
			$MimicPoly.show()
			$ChestPoly.hide()
		State.HIDDEN:
			$MimicPoly.hide()
			$ChestPoly.show()

	state = new_state

func interact() -> void:
	match state:
		State.NONE:
			set_state(State.HIDDEN)
		State.HIDDEN:
			set_state(State.NONE)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if player_controlled:
		get_player_input()

	match state:
		State.NONE:
			pass
		State.HIDDEN:
			input_dir = Vector2.ZERO
