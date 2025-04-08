class_name Mimic extends Entity

# NOTE all these visuals are placeholder til we get actual art
@onready var mimic_poly: Polygon2D = $FlipVisuals/MimicPoly
@onready var chest_poly: Polygon2D = $FlipVisuals/ChestPoly
@onready var flip_node: Node2D = $FlipVisuals
@onready var top_jaw: Polygon2D = $Attack/TopJaw
@onready var bot_jaw: Polygon2D = $Attack/BottomJaw
@onready var attack_node: Node2D = $Attack

@onready var hitbox: Hitbox = $Attack/Hitbox

enum State { NONE, HIDDEN, ATTACK }
var state: State = State.NONE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assign_player_is_controlled()
	interacted.connect(interact)
	attacked.connect(attack)
	set_state(State.NONE)

func set_state(new_state: State) -> void:
	match new_state:
		State.NONE:
			mimic_poly.show()
			chest_poly.hide()
			attack_node.hide()
		State.HIDDEN:
			mimic_poly.hide()
			chest_poly.show()
			attack_node.hide()
		State.ATTACK:
			# TODO replace with real animation
			update_visual_dir()
			top_jaw.rotation_degrees = 0
			bot_jaw.rotation_degrees = 0
			attack_node.show()
			var top_tween = get_tree().create_tween()
			top_tween.tween_interval(0.1)
			top_tween.tween_property(top_jaw, "rotation_degrees", 47, 0.1)
			top_tween.tween_callback(func (): hitbox.activate())
			top_tween.tween_interval(0.4)
			top_tween.tween_callback(func (): set_state(State.NONE))
			var bot_tween = get_tree().create_tween()
			bot_tween.tween_interval(0.1)
			bot_tween.tween_property(bot_jaw, "rotation_degrees", -19.6, 0.1)

	state = new_state

func interact() -> void:
	match state:
		State.NONE:
			set_state(State.HIDDEN)
		State.HIDDEN:
			set_state(State.NONE)

func attack() -> void:
	match state:
		State.ATTACK:
			return
	# TODO remove/change when real visuals exist.
	# show green mimic again, first
	set_state(State.NONE)
	set_state(State.ATTACK)

func hit(hitbox: Hitbox) -> void:
	# TODO?
	#Events.entity_destroyed.emit(self)
	queue_free()

func update_visual_dir() -> void:
	attack_node.rotation = face_dir.angle()
	if face_dir.x < 0:
		flip_node.scale.x = -1
	elif face_dir.x > 0:
		flip_node.scale.x = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if player_controlled:
		get_player_input()

	match state:
		State.NONE:
			update_face_dir()
			update_visual_dir()
		State.HIDDEN:
			update_face_dir()
			input_dir = Vector2.ZERO
		State.ATTACK:
			input_dir = Vector2.ZERO
