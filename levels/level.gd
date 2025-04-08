class_name Level
extends Node

@onready var floor_tiles: TileMapLayer = $FloorTiles
@onready var other_tiles: TileMapLayer = $OtherTiles
@onready var wall_tiles: TileMapLayer = $WallTiles

@export var max_heroes: int = 1
@export var max_monsters: int = 1

var hero_spawn_points: Array[SpawnPoint] = []
var monster_spawn_points: Array[SpawnPoint] = []
var chest_spawn_points: Array[SpawnPoint] = []
var sight_orb_spawn_points: Array[SpawnPoint] = []

func create_spawn_point(coord: Vector2i, time_secs: float) -> SpawnPoint:
	var point = preload("res://levels/spawn_point.tscn").instantiate()
	add_child(point)
	point.coord = coord
	point.time_secs = time_secs
	point.position = other_tiles.map_to_local(coord)
	return point

func _ready() -> void:
	# get the spawner tiles
	var coords = other_tiles.get_used_cells()
	for coord: Vector2i in coords:
		var tile_data: TileData = other_tiles.get_cell_tile_data(coord)
		if tile_data.get_custom_data("stairs_up"):
			hero_spawn_points.append(create_spawn_point(coord, 0.5))
		if tile_data.get_custom_data("stairs_down"):
			monster_spawn_points.append(create_spawn_point(coord, 0.5))
		if tile_data.get_custom_data("chest"):
			chest_spawn_points.append(create_spawn_point(coord, 10))
		if tile_data.get_custom_data("sight_orb"):
			sight_orb_spawn_points.append(create_spawn_point(coord, 10))

func coord_is_wall(coord: Vector2i) -> bool:
	var tile_data: TileData = wall_tiles.get_cell_tile_data(coord)
	if !tile_data:
		return false
	var is_wall = tile_data.get_custom_data("wall")
	return is_wall
