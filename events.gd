extends Node

signal main_char_entered_screen(screen: LevelScreen)
signal screen_ended(screen: LevelScreen)
signal character_spawned(node: Node2D, gpos: Vector2)
signal vfx_spawned(node: Node2D, gpos: Vector2)
signal main_char_attacked
