class_name Chest extends Entity

func collect(entity):
	Events.chest_destroyed.emit(self)
	# can't free here because the collectible may be used later
	get_parent().remove_child(self)
