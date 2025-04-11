class_name Chest extends Entity

func collect():
	Events.entity_collected.emit(self)
	# can't free here because the collectible may be used later
	get_parent().remove_child(self)
