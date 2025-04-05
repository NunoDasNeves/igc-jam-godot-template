class_name Level
extends Node

@onready var floor_tiles: TileMapLayer = $FloorTiles
@onready var other_tiles: TileMapLayer = $OtherTiles
@onready var wall_tiles: TileMapLayer = $WallTiles

var stairs_up_coords: Array[Vector2i] = []
var stairs_down_coords: Array[Vector2i] = []

func _ready() -> void:
	# get the spawner tiles
	var coords = other_tiles.get_used_cells()
	for coord: Vector2i in coords:
		var tile_data: TileData = other_tiles.get_cell_tile_data(coord)
		if tile_data.get_custom_data("stairs_up"):
			stairs_up_coords.append(coord)
		if tile_data.get_custom_data("stairs_down"):
			stairs_down_coords.append(coord)

func coord_is_wall(coord: Vector2i) -> bool:
	var tile_data: TileData = wall_tiles.get_cell_tile_data(coord)
	if !tile_data:
		return false
	var is_wall = tile_data.get_custom_data("wall")
	return is_wall
