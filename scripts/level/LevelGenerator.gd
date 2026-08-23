class_name LevelGenerator extends Node

signal initial_generation_finished

@export var tilemap : LevelMap
@export var terrain_set_id : int = 0
@export var terrain_id : int = 0

@export var tile_generate_chance : float = 0.25
@export var unload_buffer : int = 2

@export_group("Performance")
@export var tiles_per_frame_budget : int = 128  ## Max tile cells scanned per frame while generating a chunk. Lower = smoother framerate, higher = faster loading.
@export var unload_chunks_per_frame : int = 1   ## Max full chunk unloads processed per frame.

@onready var player = get_parent().get_parent().player as Player

var tile_damage : Dictionary[Vector2i, int] = {}

var cave_noise : FastNoiseLite = FastNoiseLite.new()
var loaded_chunks := {}
var generation_queue : Array[Vector2i] = []
var unload_queue : Array[Vector2i] = []
var last_player_chunk := Vector2i(999999, 999999)

var modified_tiles := {}

var is_generating : bool = false
var is_initial_generation : bool = true
var initial_generation_complete : bool = false

var _gen_active : bool = false
var _gen_start_x : int = 0
var _gen_start_y : int = 0
var _gen_x : int = 0
var _gen_y : int = 0
var _gen_tiles_to_place : Array[Vector2i] = []

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	cave_noise.frequency = 0.03
	cave_noise.fractal_type = FastNoiseLite.FRACTAL_FBM

func _generate_chunk_ores(tiles : Array[Vector2i]) -> void:
	if tiles.is_empty():
		return

	var available_set : Dictionary = {}
	for t in tiles:
		available_set[t] = true

	for ore_type : BlockSetting in GenerationSettings.ores:
		if rng.randf() > ore_type.gen_chance:
			continue

		var vein := _grow_vein(rng.randi_range(ore_type.min_size, ore_type.max_size), available_set)
		if vein.is_empty():
			continue

		var bd := BlockDatabase.get_block_by_id(ore_type.block_id)
		if bd == null:
			continue

		for pos in vein:
			modified_tiles[pos] = ore_type.block_id
			available_set.erase(pos)

		tilemap.set_cells_terrain_connect(vein, bd.terrain_set_id, bd.terrain_id)

func generate_initial_world() -> void:
	cave_noise.seed = GameSettings.seed_
	is_initial_generation = true
	initial_generation_complete = false
	is_generating = true

	loaded_chunks.clear()
	modified_tiles.clear()
	tile_damage.clear()
	_gen_active = false
	generation_queue.clear()

	var start_pos = Vector2.ZERO
	var center_tile = tilemap.local_to_map(start_pos)
	var center_chunk_x = int(floor(float(center_tile.x) / GameSettings.chunk_size))
	var center_chunk_y = int(floor(float(center_tile.y) / GameSettings.chunk_size))

	last_player_chunk = Vector2i(center_chunk_x, center_chunk_y)

	generation_queue.clear()

	var initial_chunks: Array[Vector2i] = []
	for x in range(center_chunk_x - GameSettings.render_distance, center_chunk_x + GameSettings.render_distance + 1):
		for y in range(center_chunk_y - GameSettings.render_distance, center_chunk_y + GameSettings.render_distance + 1):
			initial_chunks.append(Vector2i(x, y))

	initial_chunks.sort_custom(func(a, b):
		var dist_a = a.distance_squared_to(Vector2i(center_chunk_x, center_chunk_y))
		var dist_b = b.distance_squared_to(Vector2i(center_chunk_x, center_chunk_y))
		return dist_a < dist_b
	)

	generation_queue.append_array(initial_chunks)

func _grow_vein(target_size: int, available_set: Dictionary) -> Array[Vector2i]:
	if available_set.is_empty() or target_size <= 0:
		return []

	var available_keys := available_set.keys()
	var start : Vector2i = available_keys[rng.randi() % available_keys.size()]

	var vein : Array[Vector2i] = [start]
	var vein_set : Dictionary = {start: true}
	var frontier : Array[Vector2i] = [start]

	var dirs := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

	while vein.size() < target_size and not frontier.is_empty():
		var grow_from : Vector2i = frontier[rng.randi() % frontier.size()]

		var shuffled_dirs := dirs.duplicate()
		shuffled_dirs.shuffle()

		var grew := false
		for dir in shuffled_dirs:
			var candidate = grow_from + dir
			if available_set.has(candidate) and not vein_set.has(candidate):
				vein.append(candidate)
				vein_set[candidate] = true
				frontier.append(candidate)
				grew = true
				break

		if not grew:
			frontier.erase(grow_from)

	return vein

func _process(_delta: float) -> void:
	if not is_generating:
		return

	# Resume the in-progress chunk, or start the next queued one — each
	# call only does up to `tiles_per_frame_budget` worth of work, so a
	# single chunk can now span several frames instead of spiking one.
	if _gen_active:
		_step_chunk_generation()
	elif generation_queue.size() > 0:
		var next_chunk = generation_queue.pop_front()
		if not loaded_chunks.has(next_chunk):
			_begin_chunk_generation(next_chunk.x, next_chunk.y)
			loaded_chunks[next_chunk] = true

	_step_unload_queue()

	if is_initial_generation and generation_queue.is_empty() and not _gen_active:
		is_initial_generation = false
		initial_generation_complete = true
		_on_initial_generation_finished()

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

func _on_initial_generation_finished() -> void:
	initial_generation_finished.emit()

func update_chunks(world_position: Vector2) -> void:
	var center_tile = tilemap.local_to_map(world_position)
	var center_chunk_x = int(floor(float(center_tile.x) / GameSettings.chunk_size))
	var center_chunk_y = int(floor(float(center_tile.y) / GameSettings.chunk_size))

	var new_chunks_to_queue := []

	for x in range(center_chunk_x - GameSettings.render_distance, center_chunk_x + GameSettings.render_distance + 1):
		for y in range(center_chunk_y - GameSettings.render_distance, center_chunk_y + GameSettings.render_distance + 1):
			var chunk_key = Vector2i(x, y)
			if not loaded_chunks.has(chunk_key) and not generation_queue.has(chunk_key):
				new_chunks_to_queue.append(chunk_key)

	new_chunks_to_queue.sort_custom(func(a, b):
		var dist_a = a.distance_squared_to(Vector2i(center_chunk_x, center_chunk_y))
		var dist_b = b.distance_squared_to(Vector2i(center_chunk_x, center_chunk_y))
		return dist_a < dist_b
	)

	generation_queue.append_array(new_chunks_to_queue)

	# UNLOAD FARAWAY CHUNKS — mark them unloaded from tracking immediately
	# (so they don't get re-queued for generation), but defer the actual
	# erase/light work to the budgeted unload queue below.
	var unload_limit = GameSettings.render_distance + unload_buffer
	var chunks_to_remove := []

	for chunk_key in loaded_chunks.keys():
		var dist_x = abs(chunk_key.x - center_chunk_x)
		var dist_y = abs(chunk_key.y - center_chunk_y)

		if dist_x > unload_limit or dist_y > unload_limit:
			if not unload_queue.has(chunk_key):
				unload_queue.append(chunk_key)
			chunks_to_remove.append(chunk_key)

	for key in chunks_to_remove:
		loaded_chunks.erase(key)

	generation_queue = generation_queue.filter(func(chunk_key):
		var dist_x = abs(chunk_key.x - center_chunk_x)
		var dist_y = abs(chunk_key.y - center_chunk_y)
		return dist_x <= unload_limit and dist_y <= unload_limit
	)

func _begin_chunk_generation(chunk_x: int, chunk_y: int) -> void:
	_gen_active = true
	_gen_start_x = chunk_x * GameSettings.chunk_size
	_gen_start_y = chunk_y * GameSettings.chunk_size
	_gen_x = 0
	_gen_y = 0
	_gen_tiles_to_place.clear()

## Scans up to `tiles_per_frame_budget` cells of the chunk currently being
## generated, resuming from where it left off. When the whole chunk has
## been scanned, places the base terrain and ores in single batched calls.
func _step_chunk_generation() -> void:
	var processed := 0
	var chunk_size := GameSettings.chunk_size

	while _gen_y < chunk_size:
		while _gen_x < chunk_size:
			if processed >= tiles_per_frame_budget:
				return # pick up here next frame

			var x := _gen_start_x + _gen_x
			var y := _gen_start_y + _gen_y
			var tile_pos := Vector2i(x, y)

			if modified_tiles.has(tile_pos):
				var stored_id = modified_tiles[tile_pos]
				if stored_id != -1:
					var bd := BlockDatabase.get_block_by_id(stored_id)
					if bd:
						tilemap.set_cells_terrain_connect([tile_pos], bd.terrain_set_id, bd.terrain_id)
				else:
					tilemap.erase_cell(tile_pos)
			else:
				var cave_val = cave_noise.get_noise_2d(x, y)
				if cave_val > tile_generate_chance:
					tilemap.erase_cell(tile_pos)
				else:
					_gen_tiles_to_place.append(tile_pos)

			processed += 1
			_gen_x += 1

		_gen_x = 0
		_gen_y += 1

	_finish_chunk_generation()

func _finish_chunk_generation() -> void:
	if _gen_tiles_to_place.size() > 0:
		tilemap.set_cells_terrain_connect(_gen_tiles_to_place, terrain_set_id, terrain_id)
		_generate_chunk_ores(_gen_tiles_to_place)

	tilemap.spawn_chunk_lights(_gen_start_x / GameSettings.chunk_size, _gen_start_y / GameSettings.chunk_size)

	_gen_active = false
	_gen_tiles_to_place = []

func _step_unload_queue() -> void:
	var ops := 0
	while ops < unload_chunks_per_frame and unload_queue.size() > 0:
		var chunk_key : Vector2i = unload_queue.pop_front()
		unload_chunk(chunk_key.x, chunk_key.y)
		ops += 1

func unload_chunk(chunk_x: int, chunk_y: int) -> void:
	var start_x = chunk_x * GameSettings.chunk_size
	var start_y = chunk_y * GameSettings.chunk_size

	tilemap.unload_chunk_lights(chunk_x, chunk_y)

	for x in range(start_x, start_x + GameSettings.chunk_size):
		for y in range(start_y, start_y + GameSettings.chunk_size):
			tilemap.erase_cell(Vector2i(x, y))

func modify_tile(tile_pos: Vector2i, is_solid: bool, block_id: int = -1) -> int:
	if is_solid:
		var block_data := BlockDatabase.get_block_by_id(block_id)
		if block_data == null:
			return -1
		modified_tiles[tile_pos] = block_id
		tilemap.set_cells_terrain_connect([tile_pos], block_data.terrain_set_id, block_data.terrain_id)
		tilemap.spawn_light_at(tile_pos)
		return block_id
	else:
		var td : TileData = tilemap.get_cell_tile_data(tile_pos)
		var removed_id : int = td.get_custom_data("block_id") if td else -1
		modified_tiles[tile_pos] = -1
		tilemap.set_cells_terrain_connect([tile_pos], terrain_set_id, -1)
		tilemap.remove_light_at(tile_pos)
		return removed_id
		
func damage_tile(tile_pos: Vector2i, amount: int, tool_strength: int) -> Dictionary:
	var td : TileData = tilemap.get_cell_tile_data(tile_pos)
	if td == null:
		return {}

	var block_data := BlockDatabase.get_block_by_id(td.get_custom_data("block_id"))
	if block_data == null or tool_strength < block_data.required_strength:
		return {"broken": false, "blocked": true, "block_data": block_data}

	tile_damage[tile_pos] = tile_damage.get(tile_pos, 0) + amount

	if tile_damage[tile_pos] >= block_data.hardness:
		tile_damage.erase(tile_pos)
		return {"broken": true, "block_id": modify_tile(tile_pos, false), "block_data": block_data}

	return {
		"broken": false,
		"hits": tile_damage[tile_pos],
		"max_hits": block_data.hardness,
		"block_data": block_data,
	}
