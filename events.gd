extends Node

signal entity_collected(entity: Entity)
signal char_killed(entity: Entity)

signal relative_level_selected(rel_index: int) # relative index (+1 or -1)
signal level_changed(index: int)
signal hero_eaten
