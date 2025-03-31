extends Sprite2D

const pop_up_speed: float = 5

var initial_pos: Vector2
var pop_up_pos: Vector2
var popping_up: bool = false
var pop_up_tween: Tween

func _ready() -> void:
	initial_pos = position
	pop_up_pos = position + Vector2(0, -25)
	Events.nested_button_pressed.connect(pop_up)

func pop_up(_pos: Vector2) -> void:
	if pop_up_tween:
		pop_up_tween.stop()
	pop_up_tween = get_tree().create_tween()
	pop_up_tween.tween_property(self, "position", pop_up_pos, 0.5)
	pop_up_tween.tween_interval(1)
	pop_up_tween.tween_property(self, "position", initial_pos, 0.5)
