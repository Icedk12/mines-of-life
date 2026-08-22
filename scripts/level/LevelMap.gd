class_name LevelMap extends TileMapLayer

@export var light_scene: PackedScene
@export var target_terrain_set: int = 0
@export var target_terrain: int = 3 # ID of the torch/light terrain

var chunk_lights: Dictionary = {}

func spawn_chunk_lights(chunk_x: int, chunk_y: int) -> void:
	var chunk_key := Vector2i(chunk_x, chunk_y)
	
	# Skip if lights for this chunk are already loaded
	if chunk_lights.has(chunk_key):
		return
		
	var start_x = chunk_x * GameSettings.chunk_size
	var start_y = chunk_y * GameSettings.chunk_size
	var lights_in_chunk: Array[Node2D] = []

	# Scan only the tiles belonging to this specific chunk
	for x in range(start_x, start_x + GameSettings.chunk_size):
		for y in range(start_y, start_y + GameSettings.chunk_size):
			var cell := Vector2i(x, y)
			var tile_data: TileData = get_cell_tile_data(cell)
			
			if tile_data and tile_data.terrain_set == target_terrain_set and tile_data.terrain == target_terrain:
				var light := light_scene.instantiate() as Node2D
				add_child(light)
				light.position = map_to_local(cell)
				lights_in_chunk.append(light)

	if not lights_in_chunk.is_empty():
		chunk_lights[chunk_key] = lights_in_chunk

func unload_chunk_lights(chunk_x: int, chunk_y: int) -> void:
	var chunk_key := Vector2i(chunk_x, chunk_y)
	
	if chunk_lights.has(chunk_key):
		for light in chunk_lights[chunk_key]:
			if is_instance_valid(light):
				light.queue_free()
		chunk_lights.erase(chunk_key)

func reload_chunk_lights(chunk_x: int, chunk_y: int) -> void:
	unload_chunk_lights(chunk_x, chunk_y)
	spawn_chunk_lights(chunk_x, chunk_y)
