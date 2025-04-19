class_name Mimic extends Entity

# NOTE all these visuals are placeholder til we get actual art
@onready var mimic_poly: Polygon2D = $FlipVisuals/MimicPoly
@onready var chest_poly: Polygon2D = $FlipVisuals/ChestPoly
@onready var flip_node: Node2D = $FlipVisuals
@onready var top_jaw: Polygon2D = $Attack/TopJaw
@onready var bot_jaw: Polygon2D = $Attack/BottomJaw
@onready var attack_node: Node2D = $Attack
@onready var hitbox: Hitbox = $Attack/Hitbox
@onready var inventory: Inventory = %Inventory
@onready var status_sight_node: Node2D = $StatusSight
@onready var glitter: GPUParticles2D = $Glitter

#------------------------------------------------------[Mimic Class Signals]---------------------------------------------------------------------------
## signal to triger Hero in being attracted to mimic. 
signal _is_attracting_hero_signal()


@export var _is_attracting_hero: bool = false

enum State { NONE, HIDDEN, ATTACK, DIE }
var state: State = State.NONE

var state_tween: Tween
var anim_tween: Tween






func _ready() -> void:
	interacted.connect(interact)
	attacked.connect(attack)
	hitbox.connect("hit_entity", attack_hit)
	set_state(State.NONE)



#------------------------------------------------------[MimicClass State Machine]---------------------------------------------------------------------------
func set_state(new_state: State) -> void:
	if state_tween:
		state_tween.stop()

	match new_state:
		State.NONE:
			mimic_poly.show()
			chest_poly.hide()
			attack_node.hide()
			collision_layer = 1
			remove_from_group("chest")
			collectible = false
		State.HIDDEN:
			mimic_poly.hide()
			chest_poly.show()
			attack_node.hide()
			collision_layer = 4
			add_to_group("chest")
			collectible = true
		State.ATTACK:
			# TODO replace with real animation
			update_visual_dir()
			top_jaw.rotation_degrees = 0
			bot_jaw.rotation_degrees = 0
			attack_node.show()
			anim_tween = get_tree().create_tween()
			anim_tween.tween_interval(0.1)
			anim_tween.set_parallel(true)
			anim_tween.set_ease(Tween.EASE_IN)
			anim_tween.tween_property(top_jaw, "rotation_degrees", 47, 0.1)
			anim_tween.tween_property(bot_jaw, "rotation_degrees", -19.6, 0.1)
			anim_tween.tween_property(self, "position", position + face_dir * 20, 0.1)
			anim_tween.set_ease(Tween.EASE_OUT)
			anim_tween.chain().tween_property(self, "position", position, 0.15)
			state_tween = get_tree().create_tween()
			state_tween.tween_callback(func (): hitbox.activate())
			state_tween.tween_interval(0.32)
			state_tween.tween_callback(func (): set_state(State.NONE))
			#anim_tween.chain().tween_subtween(state_tween)
		State.DIE:
			if anim_tween:
				anim_tween.stop()
			mimic_poly.show()
			chest_poly.hide()
			attack_node.hide()
			state_tween = get_tree().create_tween()
			state_tween.tween_callback(func ():
				Events.char_killed.emit(self)
				queue_free()
			)

	state = new_state
#------------------------------------------------------[Mimic Class Actions]---------------------------------------------------------------------------
func interact() -> void:
	match state:
		State.NONE:
			set_state(State.HIDDEN)
		State.HIDDEN:
			set_state(State.NONE)

func attack_hit(other: Entity) -> void:
	if other.collectible:
		other.collect()
		inventory.pocket.append(other)
		do_collect(other)
		check_if_attracting_hero()
			

func attack() -> void:
	match state:
		State.ATTACK:
			return
	# TODO remove/change when real visuals exist.
	# show green mimic again, first
	set_state(State.NONE)
	set_state(State.ATTACK)

func collect():
	set_state(State.NONE)

@warning_ignore("unused_parameter", "shadowed_variable")
func hit(hitbox: Hitbox) -> void:
	# TODO?
	#Events.entity_destroyed.emit(self)
	set_state(State.DIE)




#------------------------------------------------------[Mimic Class Checks]---------------------------------------------------------------------------
func check_if_attracting_hero() -> void:
	print(gold_pocket, "check_if_attracting_hero")
	if gold_pocket <= 3:
		_is_attracting_hero = true
		emit_signal("_is_attracting_hero_signal")
		glitter.visible = true
		print("check_if_attracting_hero")
		

#------------------------------------------------------[Mimic Class Update Direction]---------------------------------------------------------------------------

func update_visual_dir() -> void:
	attack_node.rotation = face_dir.angle()
	if face_dir.x < 0:
		flip_node.scale.x = -1
	elif face_dir.x > 0:
		flip_node.scale.x = 1

#------------------------------------------------------[Mimic Class Process Function]--------------------------------------------------------------
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
