class_name SightOrb extends Entity

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	animated_sprite_2d.play("default")

func collect():
	Events.entity_collected.emit(self)
	# can't free here because the collectible may be used later
	get_parent().remove_child(self)
