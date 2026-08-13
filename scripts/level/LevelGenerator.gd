class_name LevelGenerator extends Node

@export var tilemap : TileMapLayer ## TileMapLayer
@export var terrain_set_id : int = 0  ## The index of Terrain Set (usually 0)
@export var terrain_id : int = 0 ## The index of specific Terrain (e.g., "Couch" / Ground)

@export var tile_generate_chance : float = 0.25

var cave_noise : FastNoiseLite = FastNoiseLite.new()
var loaded_chunks := {}

func _ready() -> void:
	cave_noise.seed = GameSettings.seed_
	cave_noise.frequency = 0.03
	cave_noise.fractal_type = FastNoiseLite.FRACTAL_FBM

func generate_chunk(chunk_x: int, chunk_y: int) -> void:
	var start_x = chunk_x * GameSettings.chunk_size
	var start_y = chunk_y * GameSettings.chunk_size
	
	# Collect all tiles that should be SOLID in this chunk
	var tiles_to_place: Array[Vector2i] = []
	
	for x in range(start_x, start_x + GameSettings.chunk_size):
		for y in range(start_y, start_y + GameSettings.chunk_size):
			var tile_pos : Vector2i = Vector2i(x, y)
			var cave_val = cave_noise.get_noise_2d(x, y)
			
			if cave_val > tile_generate_chance:
				# Air tile
				tilemap.erase_cell(tile_pos)
			else:
				# Solid wall tile
				tiles_to_place.append(tile_pos)
				
	if tiles_to_place.size() > 0:
		tilemap.set_cells_terrain_connect(tiles_to_place, terrain_set_id, terrain_id)
