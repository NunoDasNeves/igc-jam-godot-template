extends Node

signal entity_collected(entity: Entity)
signal char_killed(entity: Entity)

signal relative_level_selected(rel_index: int) # relative index (+1 or -1)
signal level_changed(index: int)
signal level_complete(index: int, deaths: int)
signal hunger_bar_full
signal hero_eaten
signal win_game(total_deaths: int)

signal play_clicked
signal options_clicked
signal options_closed
signal back_to_main_menu_clicked
signal next_level_clicked
signal resume_clicked
