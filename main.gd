class_name Main extends Node

@onready var pause_menu = $UI/PauseMenu
@onready var level_completed_menu: PanelContainer = $UI/LevelCompletedMenu
@onready var win_game: PanelContainer = $UI/WinGame
@onready var main_menu: PanelContainer = $UI/MainMenu
@onready var options: PanelContainer = $UI/Options
@onready var world: World = $World

enum Screen { MAIN_MENU, GAME, LEVEL_END, WIN_GAME }
var screen = Screen.MAIN_MENU
# options and pause aren't considered 'screens'
var options_open: bool = false

func _enter_tree() -> void:
	Global.main = self

func _ready() -> void:
	main_menu.show()
	pause_menu.hide()
	level_completed_menu.hide()
	win_game.hide()
	options.hide()

	Events.play_clicked.connect(func():
		set_screen(Screen.GAME)
		world.reset_game()
	)
	Events.options_clicked.connect(open_options)
	Events.options_closed.connect(close_options)
	Events.win_game.connect(func(_deaths):
		set_screen(Screen.WIN_GAME)
	)
	Events.back_to_main_menu_clicked.connect(func():
		set_screen(Screen.MAIN_MENU)
		world.unload_curr_level()
	)
	Events.level_complete.connect(func(_idx, _deaths):
		set_screen(Screen.LEVEL_END)
	)
	Events.next_level_clicked.connect(func():
		Events.relative_level_selected.emit(1)
		set_screen(Screen.GAME)
	)
	Events.resume_clicked.connect(func():
		set_paused(false)
	)

func set_screen(val: Screen) -> void:
	main_menu.hide()
	pause_menu.hide()
	level_completed_menu.hide()
	win_game.hide()
	options.hide()
	options_open = false

	match val:
		Screen.MAIN_MENU:
			main_menu.show()
		Screen.GAME:
			pass
		Screen.LEVEL_END:
			level_completed_menu.show()
		Screen.WIN_GAME:
			win_game.show()

	screen = val

func set_paused(val: bool) -> void:
	get_tree().paused = val
	pause_menu.visible = val
	Audio.play_sfx("unpause_close_menu.wav")

func close_options():
	options.hide()
	if !get_tree().paused:
		set_screen(screen)
	options_open = false

func open_options():
	options.show()
	options_open = true

func _unhandled_key_input(event: InputEvent) -> void:
	if event.keycode == KEY_ESCAPE and event.pressed and !event.echo:
		if screen == Screen.MAIN_MENU:
			return
		if get_tree().paused:
			if options_open:
				close_options()
			else:
				set_paused(false)
		else:
			set_paused(true)
