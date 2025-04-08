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

func create_spawn_point(coord: Vector2i, cooldown_secs: float = 0) -> SpawnPoint:
	var point = preload("res://levels/spawn_point.tscn").instantiate()
	point.coord = coord
	point.cooldown_secs = cooldown_secs
	point.position = other_tiles.map_to_local(coord)
	add_child(point)
	return point

func _ready() -> void:
	# get the spawner tiles
	var other_coords = other_tiles.get_used_cells()
	for coord: Vector2i in other_coords:
		var tile_data: TileData = other_tiles.get_cell_tile_data(coord)
		if tile_data.get_custom_data("stairs_up"):
			hero_spawn_points.append(create_spawn_point(coord, 0.5))
		if tile_data.get_custom_data("stairs_down"):
			monster_spawn_points.append(create_spawn_point(coord, 0.5))
		if tile_data.get_custom_data("chest"):
			chest_spawn_points.append(create_spawn_point(coord))
		if tile_data.get_custom_data("sight_orb"):
			sight_orb_spawn_points.append(create_spawn_point(coord))

	# create pathing tiles
	var floor_coords = floor_tiles.get_used_cells()
	#floor_tiles.get_cell_atlas_coords()
	var src_id = floor_tiles.get_cell_source_id(Vector2(0,0))
	for coord: Vector2i in floor_coords:
		var floor_tile = floor_tiles.get_cell_tile_data(coord)
		if !floor_tile:
			continue
		var wall_tile: TileData = wall_tiles.get_cell_tile_data(coord)
		if !wall_tile or !wall_tile.get_custom_data("wall"):
			floor_tiles.set_cell(coord, src_id, Vector2(0,0), 1)

func coord_is_wall(coord: Vector2i) -> bool:
	var tile_data: TileData = wall_tiles.get_cell_tile_data(coord)
	if !tile_data:
		return false
	var is_wall = tile_data.get_custom_data("wall")
	return is_wall
