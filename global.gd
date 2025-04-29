extends Node

@onready var is_web = OS.has_feature("web")

var coll_layers: Dictionary[String, int] = {}

var main: Main
var world: World

func _ready() -> void:
	for i in range(1,33):
		var layer_name = ProjectSettings.get_setting("layer_names/2d_physics/layer_" + str(i))
		# bitmask so we can OR them together
		coll_layers[layer_name] = 1 << (i - 1)
