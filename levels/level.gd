class_name Level extends Node

@onready var floor_tiles: TileMapLayer = $FloorTiles
@onready var other_tiles: TileMapLayer = $OtherTiles
@onready var wall_tiles: TileMapLayer = $WallTiles

@export var max_heroes: int = 1
@export var max_monsters: int = 1


class Spawner extends RefCounted:
	var coord: Vector2i
	var timer: SceneTreeTimer

var hero_spawners: Array[Spawner] = []
var monster_spawners: Array[Spawner] = []

func _ready() -> void:
	# get the spawner tiles
	var coords = other_tiles.get_used_cells()
	for coord: Vector2i in coords:
		var tile_data: TileData = other_tiles.get_cell_tile_data(coord)
		var spawns_heroes = tile_data.get_custom_data("stairs_up")
		var spawns_monsters = tile_data.get_custom_data("stairs_down")
		if spawns_heroes or spawns_monsters:
			var spawner = Spawner.new()
			spawner.coord = coord
			spawner.timer = get_tree().create_timer(0.5)
			if spawns_heroes:
				hero_spawners.append(spawner)
			if spawns_monsters:
				monster_spawners.append(spawner)






func coord_is_wall(coord: Vector2i) -> bool:
	var tile_data: TileData = wall_tiles.get_cell_tile_data(coord)
	if !tile_data:
		return false
	var is_wall = tile_data.get_custom_data("wall")
	return is_wall
