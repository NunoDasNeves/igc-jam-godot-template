class_name SightOrb extends Entity

func collect(Entity):
	Events.sight_orb_destroyed.emit(self)
	# can't free here because the collectible may be used later
	get_parent().remove_child(self)
