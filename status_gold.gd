class_name StatusGold extends Node2D

const gold_piece_scene = preload("res://gold_piece.tscn")

@onready var gold_container: Node2D = $GoldContainer

var tween: Tween
var count: int = 1 # NOTE gets cleared on _ready()

func _ready() -> void:
	clear()

func add_one():
	assert(count == gold_container.get_child_count())
	var piece = gold_piece_scene.instantiate()
	gold_container.add_child(piece)
	piece.position.x = count * 10
	# center the container
	gold_container.position.x = -count * 10 * 0.5
	count += 1

func show_then_fade():
	if tween:
		tween.stop()
	gold_container.modulate.a = 1
	tween = get_tree().create_tween()
	tween.tween_interval(3)
	tween.tween_property(gold_container, "modulate:a", 0, 3)

func clear():
	assert(count == gold_container.get_child_count())
	Util.remove_all_children(gold_container)
	count = 0
	gold_container.position.x = 0
