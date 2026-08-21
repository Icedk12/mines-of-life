class_name LevelGenerator extends Node

@export var tilemap : TileMapLayer
@export var terrain_set_id : int = 0
@export var terrain_id : int = 0

@export var tile_generate_chance : float = 0.25
@export var unload_buffer : int = 2

@onready var player = get_parent().get_parent().player as Player

var cave_noise : FastNoiseLite = FastNoiseLite.new()
var loaded_chunks := {}
var generation_queue : Array[Vector2i] = [] # Queue for time-slicing
var last_player_chunk := Vector2i(999999, 999999)

var modified_tiles := {}

func _ready() -> void:
	cave_noise.seed = GameSettings.seed_
	cave_noise.frequency = 0.03
	cave_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	
	var start_pos = player.global_position if player else Vector2.ZERO
	update_chunks(start_pos)

func _process(_delta: float) -> void:
	# Process one chunk from the queue per frame to prevent frame spikes
	if generation_queue.size() > 0:
		var next_chunk = generation_queue.pop_front()
		# Make sure it wasn't loaded in the meantime
		if not loaded_chunks.has(next_chunk):
			generate_chunk(next_chunk.x, next_chunk.y)
			loaded_chunks[next_chunk] = true

	if not player:
		return
		
	var player_tile = tilemap.local_to_map(player.global_position)
	var current_chunk = Vector2i(
		int(floor(float(player_tile.x) / GameSettings.chunk_size)),
		int(floor(float(player_tile.y) / GameSettings.chunk_size))
	)
	
	if current_chunk != last_player_chunk:
		last_player_chunk = current_chunk
		update_chunks(player.global_position)

func update_chunks(world_position: Vector2) -> void:
	var center_tile = tilemap.local_to_map(world_position)
	var center_chunk_x = int(floor(float(center_tile.x) / GameSettings.chunk_size))
	var center_chunk_y = int(floor(float(center_tile.y) / GameSettings.chunk_size))
	
	# QUEUE NEW CHUNKS (Sort by distance so closest load first)
	var new_chunks_to_queue := []
	
	for x in range(center_chunk_x - GameSettings.render_distance, center_chunk_x + GameSettings.render_distance + 1):
		for y in range(center_chunk_y - GameSettings.render_distance, center_chunk_y + GameSettings.render_distance + 1):
			var chunk_key = Vector2i(x, y)
			if not loaded_chunks.has(chunk_key) and not generation_queue.has(chunk_key):
				new_chunks_to_queue.append(chunk_key)

	# Sort queued chunks so the ones closest to the player load FIRST
	new_chunks_to_queue.sort_custom(func(a, b):
		var dist_a = a.distance_squared_to(Vector2i(center_chunk_x, center_chunk_y))
		var dist_b = b.distance_squared_to(Vector2i(center_chunk_x, center_chunk_y))
		return dist_a < dist_b
	)

	generation_queue.append_array(new_chunks_to_queue)

	# UNLOAD FARAWAY CHUNKS
	var unload_limit = GameSettings.render_distance + unload_buffer
	var chunks_to_remove := []
	
	for chunk_key in loaded_chunks.keys():
		var dist_x = abs(chunk_key.x - center_chunk_x)
		var dist_y = abs(chunk_key.y - center_chunk_y)
		
		if dist_x > unload_limit or dist_y > unload_limit:
			unload_chunk(chunk_key.x, chunk_key.y)
			chunks_to_remove.append(chunk_key)

	for key in chunks_to_remove:
		loaded_chunks.erase(key)

	# Clean up any queued chunks that moved out of render distance before generating
	generation_queue = generation_queue.filter(func(chunk_key):
		var dist_x = abs(chunk_key.x - center_chunk_x)
		var dist_y = abs(chunk_key.y - center_chunk_y)
		return dist_x <= unload_limit and dist_y <= unload_limit
	)

func generate_chunk(chunk_x: int, chunk_y: int) -> void:
	var start_x = chunk_x * GameSettings.chunk_size
	var start_y = chunk_y * GameSettings.chunk_size
	
	var tiles_to_place: Array[Vector2i] = []
	
	for x in range(start_x, start_x + GameSettings.chunk_size):
		for y in range(start_y, start_y + GameSettings.chunk_size):
			var tile_pos := Vector2i(x, y)
			
			if modified_tiles.has(tile_pos):
				if modified_tiles[tile_pos] == true:
					tiles_to_place.append(tile_pos)
				else:
					tilemap.erase_cell(tile_pos)
			else:
				var cave_val = cave_noise.get_noise_2d(x, y)
				if cave_val > tile_generate_chance:
					tilemap.erase_cell(tile_pos)
				else:
					tiles_to_place.append(tile_pos)
				
	if tiles_to_place.size() > 0:
		# terrain_connect updates autotiling borders smoothly
		tilemap.set_cells_terrain_connect(tiles_to_place, terrain_set_id, terrain_id)

func unload_chunk(chunk_x: int, chunk_y: int) -> void:
	var start_x = chunk_x * GameSettings.chunk_size
	var start_y = chunk_y * GameSettings.chunk_size
	
	for x in range(start_x, start_x + GameSettings.chunk_size):
		for y in range(start_y, start_y + GameSettings.chunk_size):
			tilemap.erase_cell(Vector2i(x, y))

func modify_tile(tile_pos: Vector2i, is_solid: bool) -> int:
	modified_tiles[tile_pos] = is_solid
	
	var td : TileData = tilemap.get_cell_tile_data(tile_pos)
	var block_id : int = td.get_custom_data("block_id") if td else -1

	if is_solid:
		tilemap.set_cells_terrain_connect([tile_pos], terrain_set_id, terrain_id)
	else:
		tilemap.set_cells_terrain_connect([tile_pos], terrain_set_id, -1)
	
	return block_id
