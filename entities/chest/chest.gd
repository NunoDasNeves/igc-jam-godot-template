class_name Chest extends Entity

func hit(hitbox: Hitbox) -> void:
	Events.chest_destroyed.emit(self)
	queue_free()

func collect():
	Events.chest_destroyed.emit(self)
	queue_free()
