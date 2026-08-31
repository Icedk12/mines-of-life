class_name LevelGenerator extends Node

#--------------------------------------------------------#
# SIGNALS
#--------------------------------------------------------#

signal initial_generation_finished

#--------------------------------------------------------#
# @EXPORT
#--------------------------------------------------------#

@export_group("General")
@export var tilemap : LevelMap

@export_group("Fallback Generation Settings")
@export var fallback_terrain_set_id : int = 0
@export var fallback_terrain_id : int = 0
@export var fallback_tile_generate_chance : float = 0.25
@export var fallback_noise_frequency : float = 0.03
@export var unload_buffer : int = 2

@export_group("Performance")
@export var frame_time_budget_msec : int = 8  ## Max milliseconds spent generating per frame (8ms targets ~120fps overhead, 16ms targets 60fps).
@export var unload_chunks_per_frame : int = 1   ## Max full chunk unloads processed per frame.

@export_group("Structures")
@export var structures : Array[StructureDefinition] ## Spawn in any layers

@export_group("Enemies")
@export var entities_parent : Node2D ## Spawn in any layers
@export var respawn_enemies_on_revisit : bool = true ## If true, enemy pools re-roll every time a chunk (re)generates. If false, a chunk only ever rolls enemies on its very first generation, same as ores/structures.

#--------------------------------------------------------#
# @ONREADY
#--------------------------------------------------------#

@onready var player = get_parent().get_parent().player as Player

#--------------------------------------------------------#
# GENERAL VARIABLES
#--------------------------------------------------------#

var loaded_enemies : int = 0
var last_player_chunk := Vector2i(999999, 999999) ## The most recent chunk the player was in

#--------------------------------------------------------#
# ARRAYS/DICTIONARIES
#--------------------------------------------------------#

# TILES
var tile_damage : Dictionary[Vector2i, int] = {}
var generation_queue : Array[Vector2i] = []
var unload_queue : Array[Vector2i] = []
var _gen_modified_tiles_to_place : Dictionary = {}
var _gen_tiles_to_erase : Array[Vector2i] = []

# CHUNKS
var modified_tiles := {}
var loaded_chunks := {}

# ENEMIES
var _chunk_enemies : Dictionary[Vector2i, Array] = {}

#--------------------------------------------------------#
# GENERATION STATUS
#--------------------------------------------------------#

var is_generating : bool = false
var is_initial_generation : bool = true
var initial_generation_complete : bool = false

var _gen_active : bool = false
var _gen_start_x : int = 0
var _gen_start_y : int = 0
var _gen_x : int = 0
var _gen_y : int = 0
var _gen_tiles_to_place : Array[Vector2i] = []  ## solid tiles queued to be stamped as terrain this chunk
var _gen_open_tiles : Array[Vector2i] = []      ## carved-out/air tiles this chunk: candidate enemy spawn points
var _gen_layer : LayerData                      ## layer resolved for the chunk currently being generated
var _gen_is_first_generation : bool = true      ## true if ChunkStorage has no save for this chunk yet

var _gen_scanning_done : bool = false
var _gen_finish_tasks : Array[Callable] = []
var _gen_lights_started : bool = false
var _gen_lights_done : bool = false

#--------------------------------------------------------#
# FALLBACK GENERATION + RNG
#--------------------------------------------------------#

var rng := RandomNumberGenerator.new()
var _layer_noise_cache : Dictionary[int, FastNoiseLite] = {} ## keyed by LayerType.Layer (int)
var _fallback_noise : FastNoiseLite = FastNoiseLite.new()

#--------------------------------------------------------#
# INBUILT GODOT FUNCTIONS
#--------------------------------------------------------#

func _ready() -> void:
	_fallback_noise.frequency = fallback_noise_frequency
	_fallback_noise.fractal_type = FastNoiseLite.FRACTAL_FBM

func _process(_delta: float) -> void:
	if not is_generating:
		return

	if _gen_active:
		_step_active_generation()
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

func _step_active_generation() -> void:
	if not _gen_scanning_done:
		_step_chunk_generation()
		return

	if not _gen_finish_tasks.is_empty():
		var task : Callable = _gen_finish_tasks.pop_front()
		task.call()
		return

	var chunk_x := _gen_start_x / GameSettings.chunk_size
	var chunk_y := _gen_start_y / GameSettings.chunk_size

	if not _gen_lights_started:
		_gen_lights_started = true
		_gen_lights_done = tilemap.begin_chunk_lights(chunk_x, chunk_y)
		return

	if not _gen_lights_done:
		_gen_lights_done = tilemap.step_chunk_lights(GameSettings.lights_per_frame_budget)
		return

	_complete_chunk_generation()

#--------------------------------------------------------#
# SIGNAL FUNCTIONS
#--------------------------------------------------------#

## Propagate the signal outwards to 
func _on_initial_generation_finished() -> void:
	initial_generation_finished.emit()

#--------------------------------------------------------#
# LOOPING FUNCTIONS
#--------------------------------------------------------#

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

#--------------------------------------------------------#
# CHUNK GENERATION FUNCTIONS
#--------------------------------------------------------#

## Generates the world for the first time and applies seed.
func generate_initial_world() -> void:
	rng.seed = GameSettings.seed_ # Seed structure/ore/enemy RNG so results are consistent per-seed
	is_initial_generation = true
	initial_generation_complete = false
	is_generating = true

	loaded_chunks.clear()
	modified_tiles.clear()
	tile_damage.clear()
	_gen_active = false
	_gen_scanning_done = false
	_gen_lights_started = false
	_gen_lights_done = false
	_gen_finish_tasks.clear()
	_layer_noise_cache.clear()
	generation_queue.clear()

	for enemies in _chunk_enemies.values():
		for enemy in enemies:
			if is_instance_valid(enemy):
				enemy.queue_free()
	_chunk_enemies.clear()

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

## Starts the generation process for a specific chunk.
func _begin_chunk_generation(chunk_x: int, chunk_y: int) -> void:
	var chunk_key := Vector2i(chunk_x, chunk_y)
	_gen_layer = _get_layer_for_chunk(chunk_x, chunk_y)
	_gen_is_first_generation = not ChunkStorage.has_chunk(GameSettings.seed_, chunk_key)

	if _gen_is_first_generation:
		_generate_chunk_structures(chunk_x, chunk_y, _gen_layer)
	else:
		_restore_chunk_from_disk(chunk_x, chunk_y, chunk_key)

	_gen_active = true
	_gen_scanning_done = false
	_gen_lights_started = false
	_gen_lights_done = false
	_gen_finish_tasks.clear()
	_gen_start_x = chunk_x * GameSettings.chunk_size
	_gen_start_y = chunk_y * GameSettings.chunk_size
	_gen_x = 0
	_gen_y = 0
	_gen_tiles_to_place.clear()
	_gen_open_tiles.clear()
	_gen_modified_tiles_to_place.clear()
	_gen_tiles_to_erase.clear()

func _step_chunk_generation() -> void:
	var start_time = Time.get_ticks_msec()
	var chunk_size = GameSettings.chunk_size
	var noise := _get_noise_for_layer(_gen_layer)
	var generate_chance := _gen_layer.tile_generate_chance if _gen_layer else fallback_tile_generate_chance
 
	while _gen_y < chunk_size:
		while _gen_x < chunk_size:
			# Yield the frame if we have exceeded our time budget
			if Time.get_ticks_msec() - start_time >= frame_time_budget_msec:
				return # pick up here next frame
 
			var x := _gen_start_x + _gen_x
			var y := _gen_start_y + _gen_y
			var tile_pos := Vector2i(x, y)
 
			if modified_tiles.has(tile_pos):
				var stored_id = modified_tiles[tile_pos]
				if stored_id != -1:
					var bd := BlockDatabase.get_block_by_id(stored_id)
					if bd:
						var key := Vector2i(bd.terrain_set_id, bd.terrain_id)
						if not _gen_modified_tiles_to_place.has(key):
							_gen_modified_tiles_to_place[key] = []
						_gen_modified_tiles_to_place[key].append(tile_pos)
				else:
					_gen_tiles_to_erase.append(tile_pos)
			else:
				var cave_val = noise.get_noise_2d(x, y)
				if cave_val > generate_chance:
					_gen_tiles_to_erase.append(tile_pos)
					_gen_open_tiles.append(tile_pos)
				else:
					_gen_tiles_to_place.append(tile_pos)
 
			_gen_x += 1
 
		_gen_x = 0
		_gen_y += 1
 
	_begin_finish_tasks()

#--------------------------------------------------------#
# TASKS
#--------------------------------------------------------#

## Queues the rest of this chunk's work as small one-shot steps
func _begin_finish_tasks() -> void:
	_gen_scanning_done = true
	_gen_finish_tasks = [
		_finish_flush_erasures,
		_finish_flush_placements,
		_finish_refresh_borders,
		_finish_ores_task,
		_finish_enemies_task,
		_finish_save_task,
	]
	
func _finish_refresh_borders() -> void:
	var chunk_x := _gen_start_x / GameSettings.chunk_size
	var chunk_y := _gen_start_y / GameSettings.chunk_size
	_refresh_neighbor_chunk_borders(chunk_x, chunk_y)

func _refresh_neighbor_chunk_borders(chunk_x: int, chunk_y: int) -> void:
	var chunk_size := GameSettings.chunk_size
	var start_x := chunk_x * chunk_size
	var start_y := chunk_y * chunk_size

	var side_offsets := [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	for off in side_offsets:
		var neighbor_key := Vector2i(chunk_x + off.x, chunk_y + off.y)
		if not loaded_chunks.has(neighbor_key):
			continue

		var cells : Array[Vector2i] = []
		if off.x == -1:
			for y in range(start_y, start_y + chunk_size):
				cells.append(Vector2i(start_x - 1, y))
		elif off.x == 1:
			for y in range(start_y, start_y + chunk_size):
				cells.append(Vector2i(start_x + chunk_size, y))
		elif off.y == -1:
			for x in range(start_x, start_x + chunk_size):
				cells.append(Vector2i(x, start_y - 1))
		else:
			for x in range(start_x, start_x + chunk_size):
				cells.append(Vector2i(x, start_y + chunk_size))

		tilemap.refresh_cells(cells)

	var corner_offsets := [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]
	for off in corner_offsets:
		var neighbor_key := Vector2i(chunk_x + off.x, chunk_y + off.y)
		if not loaded_chunks.has(neighbor_key):
			continue

		var corner_x := start_x - 1 if off.x == -1 else start_x + chunk_size
		var corner_y := start_y - 1 if off.y == -1 else start_y + chunk_size
		tilemap.refresh_cell(Vector2i(corner_x, corner_y))

func _finish_flush_erasures() -> void:
	if _gen_tiles_to_erase.size() > 0:
		tilemap.set_cells(_gen_tiles_to_erase, -1)

func _finish_flush_placements() -> void:
	var chunk_solids : Dictionary = {}
	for pos in _gen_tiles_to_place:
		chunk_solids[pos] = true
	for pos in modified_tiles.keys():
		var stored_id : int = modified_tiles[pos]
		if stored_id == -1:
			continue
		var bd := BlockDatabase.get_block_by_id(stored_id)
		if bd and not tilemap.terrain_connects(bd.terrain_id):
			continue # decorative/furniture blocks don't shape surrounding terrain
		chunk_solids[pos] = true

	if _gen_tiles_to_place.size() > 0:
		var source_id := _gen_layer.terrain_set_id if _gen_layer else fallback_terrain_set_id
		var terrain_idx := _gen_layer.terrain_id if _gen_layer and "terrain_id" in _gen_layer else 0
		tilemap.custom_terrain_connect(_gen_tiles_to_place, source_id, chunk_solids, terrain_idx)

	for key : Vector2i in _gen_modified_tiles_to_place.keys():
		var source_id := key.x
		var terrain_idx := key.y
		tilemap.custom_terrain_connect(
			_gen_modified_tiles_to_place[key],
			source_id,
			chunk_solids,
			terrain_idx
		)

## Ores only ever roll on a chunk's first-ever generation
func _finish_ores_task() -> void:
	if _gen_is_first_generation:
		_generate_chunk_ores(_gen_tiles_to_place, _gen_layer)

func _finish_enemies_task() -> void:
	if not _gen_is_first_generation and not respawn_enemies_on_revisit:
		return
	var chunk_key := Vector2i(_gen_start_x / GameSettings.chunk_size, _gen_start_y / GameSettings.chunk_size)
	_generate_chunk_enemies(chunk_key, _gen_layer, _gen_open_tiles)

func _finish_save_task() -> void:
	if _gen_is_first_generation:
		var chunk_key := Vector2i(_gen_start_x / GameSettings.chunk_size, _gen_start_y / GameSettings.chunk_size)
		_save_chunk_to_disk(chunk_key)

func _complete_chunk_generation() -> void:
	_gen_active = false
	_gen_scanning_done = false
	_gen_lights_started = false
	_gen_lights_done = false
	_gen_finish_tasks.clear()
	_gen_tiles_to_place = []
	_gen_open_tiles = []
	_gen_modified_tiles_to_place.clear()
	_gen_tiles_to_erase.clear()

#--------------------------------------------------------#
# ENEMY/ORE FUNCTIONS
#--------------------------------------------------------#

## Generates all the ores of a specific chunk.
func _generate_chunk_ores(tiles : Array[Vector2i], layer : LayerData) -> void:
	if tiles.is_empty():
		return

	var available_set : Dictionary = {}
	for t in tiles:
		available_set[t] = true

	var ore_list : Array[BlockSetting] = []
	if layer:
		ore_list.append_array(layer.ores)

	for ore_type : BlockSetting in ore_list:
		if rng.randf() > ore_type.gen_chance:
			continue
		var vein : Array[Vector2i]
		if ore_type.shape_type == BlockSetting.ShapeType.PENNY_BLOCK:
			vein = _grow_penny_vein(ore_type.min_size, ore_type.max_size, available_set)
		else:
			vein = _grow_vein(rng.randi_range(ore_type.min_size, ore_type.max_size), available_set)

		if vein.is_empty():
			continue

		var bd := BlockDatabase.get_block_by_id(ore_type.block_id)
		if bd == null:
			continue

		for pos in vein:
			modified_tiles[pos] = ore_type.block_id
			available_set.erase(pos)

		for pos in vein:
			tilemap.update_single_tile_and_neighbors(pos, bd.terrain_set_id, bd.terrain_id, false)

## Rolls the layer's enemy pool once per chunk and spawns any resulting groups
func _generate_chunk_enemies(chunk_key : Vector2i, layer : LayerData, open_tiles : Array[Vector2i]) -> void:
	if layer == null or entities_parent == null or open_tiles.is_empty():
		return
	if layer.enemy_pool.is_empty():
		return
	if rng.randf() > layer.spawn_chance_per_chunk:
		return

	var valid_tiles := _filter_valid_spawn_tiles(open_tiles)
	if valid_tiles.is_empty():
		return

	var spawned := 0
	var attempts := 0
	var max_attempts := layer.max_enemies_per_chunk * 8

	while spawned < layer.max_enemies_per_chunk and attempts < max_attempts:
		attempts += 1
		var entry := layer.pick_random_enemy()
		if entry == null or entry.enemy_scene == null:
			continue

		var tile_pos : Vector2i = valid_tiles[rng.randi() % valid_tiles.size()]
		var group_size := rng.randi_range(entry.min_group_size, entry.max_group_size)

		for i in group_size:
			var spot := tile_pos if i == 0 else valid_tiles[rng.randi() % valid_tiles.size()]

			if tilemap.get_cell_source_id(spot) != -1:
				continue

			var enemy := entry.enemy_scene.instantiate() as Node2D
			if enemy == null:
				continue
			entities_parent.add_child(enemy)
			enemy.global_position = tilemap.to_global(tilemap.map_to_local(spot))

			if enemy.has_method("setup"):
				enemy.setup(player, self)

			if not _chunk_enemies.has(chunk_key):
				_chunk_enemies[chunk_key] = []
			_chunk_enemies[chunk_key].append(enemy)
			enemy.tree_exited.connect(_on_tracked_enemy_freed.bind(chunk_key, enemy), CONNECT_ONE_SHOT)

		spawned += 1

func _filter_valid_spawn_tiles(open_tiles : Array[Vector2i]) -> Array[Vector2i]:
	var valid : Array[Vector2i] = []
	for pos in open_tiles:
		if tilemap.get_cell_source_id(pos) != -1:
			continue
		if _is_confirmed_solid_ground(pos + Vector2i.DOWN):
			valid.append(pos)
	return valid

func _is_confirmed_solid_ground(cell : Vector2i) -> bool:
	if modified_tiles.has(cell) and modified_tiles[cell] != -1:
		return true
	return tilemap.get_cell_source_id(cell) != -1

func _on_tracked_enemy_freed(chunk_key : Vector2i, enemy : Node2D) -> void:
	if _chunk_enemies.has(chunk_key):
		_chunk_enemies[chunk_key].erase(enemy)
		if _chunk_enemies[chunk_key].is_empty():
			_chunk_enemies.erase(chunk_key)

## Grows and ore vein until it is at a desired size
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

## Grows a circular vein of ore
func _grow_penny_vein(min_side : int, max_side : int, available_set : Dictionary) -> Array[Vector2i]:
	if available_set.is_empty(): return []

	var side : int = clampi(rng.randi_range(min_side, max_side), min_side, max_side)

	var available_keys := available_set.keys()
	var origin : Vector2i = available_keys[rng.randi() % available_keys.size()]

	var shape : Array[Vector2i] = []
	for x in range(side):
		for y in range(side):
			var is_corner := (x == 0 or x == side - 1) and (y == 0 or y == side - 1)
			if is_corner:
				continue

			var pos := origin + Vector2i(x, y)
			if available_set.has(pos):
				shape.append(pos)

	return shape

#--------------------------------------------------------#
# UNLOADING CHUNKS FUNCTIONS
#--------------------------------------------------------#

func _step_unload_queue() -> void:
	var ops := 0
	while ops < unload_chunks_per_frame and unload_queue.size() > 0:
		var chunk_key : Vector2i = unload_queue.pop_front()
		unload_chunk(chunk_key.x, chunk_key.y)
		ops += 1

func unload_chunk(chunk_x: int, chunk_y: int) -> void:
	var chunk_key := Vector2i(chunk_x, chunk_y)
	var start_x = chunk_x * GameSettings.chunk_size
	var start_y = chunk_y * GameSettings.chunk_size
 
	tilemap.unload_chunk_lights(chunk_x, chunk_y)
 
	var local_modified := _extract_local_modified_tiles(chunk_x, chunk_y)
	ChunkStorage.save_chunk(GameSettings.seed_, chunk_key, local_modified)
 
	var tiles_to_erase : Array[Vector2i] = []
	for x in range(start_x, start_x + GameSettings.chunk_size):
		for y in range(start_y, start_y + GameSettings.chunk_size):
			var tile_pos := Vector2i(x, y)
			tiles_to_erase.append(tile_pos)
			modified_tiles.erase(tile_pos)
			
	tilemap.set_cells(tiles_to_erase, -1)
 
	_unload_chunk_enemies(chunk_key)

## Frees every enemy still alive that was spawned in this chunk.
func _unload_chunk_enemies(chunk_key : Vector2i) -> void:
	if not _chunk_enemies.has(chunk_key):
		return
	var enemies := _chunk_enemies[chunk_key]
	_chunk_enemies.erase(chunk_key)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()

#--------------------------------------------------------#
# CHUNK PERSISTENCE HELPERS
#--------------------------------------------------------#

func _extract_local_modified_tiles(chunk_x: int, chunk_y: int) -> Dictionary:
	var start_x := chunk_x * GameSettings.chunk_size
	var start_y := chunk_y * GameSettings.chunk_size
	var local : Dictionary = {}
	for x in range(start_x, start_x + GameSettings.chunk_size):
		for y in range(start_y, start_y + GameSettings.chunk_size):
			var tile_pos := Vector2i(x, y)
			if modified_tiles.has(tile_pos):
				local[Vector2i(x - start_x, y - start_y)] = modified_tiles[tile_pos]
	return local

func _restore_chunk_from_disk(chunk_x: int, chunk_y: int, chunk_key: Vector2i) -> void:
	var local_data := ChunkStorage.load_chunk(GameSettings.seed_, chunk_key)
	if local_data.is_empty():
		return
	var start_x := chunk_x * GameSettings.chunk_size
	var start_y := chunk_y * GameSettings.chunk_size
	for local_pos in local_data.keys():
		var world_pos : Vector2i = Vector2i(start_x, start_y) + local_pos
		modified_tiles[world_pos] = local_data[local_pos]

func _save_chunk_to_disk(chunk_key: Vector2i) -> void:
	var local_modified := _extract_local_modified_tiles(chunk_key.x, chunk_key.y)
	ChunkStorage.save_chunk(GameSettings.seed_, chunk_key, local_modified)

#--------------------------------------------------------#
# PLAYER DEPENDENT FUNCTIONS
#--------------------------------------------------------#

func modify_tile(tile_pos: Vector2i, is_solid: bool, block_id: int = -1) -> int:
	if is_solid:
		var block_data := BlockDatabase.get_block_by_id(block_id)
		if block_data == null:
			return -1
		modified_tiles[tile_pos] = block_id
		
		tilemap.update_single_tile_and_neighbors(tile_pos, block_data.terrain_set_id, block_data.terrain_id, false)
		
		tilemap.spawn_light_at(tile_pos)
		return block_id
	else:
		var td : TileData = tilemap.get_cell_tile_data(tile_pos)
		var removed_id : int = td.get_custom_data("block_id") if td else -1
		modified_tiles[tile_pos] = -1
		
		tilemap.update_single_tile_and_neighbors(tile_pos, -1, 0, true)
		
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

#--------------------------------------------------------#
# STRUCTURE FUNCTIONS
#--------------------------------------------------------#

func _generate_chunk_structures(chunk_x: int, chunk_y: int, layer : LayerData) -> void:
	var combined : Array[StructureDefinition] = structures.duplicate()
	if layer:
		combined.append_array(layer.structures)

	if combined.is_empty():
		return

	for def : StructureDefinition in combined:
		if def == null or def.scene == null:
			continue
		if rng.randf() > def.spawn_chance:
			continue

		_place_structure(def.scene, chunk_x, chunk_y)

func _place_structure(scene: PackedScene, chunk_x: int, chunk_y: int) -> void:
	var source_layer := _get_structure_layer(scene)
	if source_layer == null:
		return

	var used_cells := source_layer.get_used_cells()
	if used_cells.is_empty():
		source_layer.queue_free()
		return

	var min_cell := used_cells[0]
	var max_cell := used_cells[0]
	for c in used_cells:
		min_cell = Vector2i(min(min_cell.x, c.x), min(min_cell.y, c.y))
		max_cell = Vector2i(max(max_cell.x, c.x), max(max_cell.y, c.y))
	var size := (max_cell - min_cell) + Vector2i.ONE

	var chunk_size = GameSettings.chunk_size
	var start_x = chunk_x * chunk_size
	var start_y = chunk_y * chunk_size

	var max_x = max(chunk_size - size.x, 0)
	var max_y = max(chunk_size - size.y, 0)

	var origin := Vector2i(
		start_x + rng.randi_range(0, max_x),
		start_y + rng.randi_range(0, max_y)
	) - min_cell

	_stamp_structure(source_layer, origin)
	source_layer.queue_free()

func _stamp_structure(source_layer: TileMapLayer, origin: Vector2i) -> void:
	var tile_set := tilemap.tile_set
	if tile_set == null:
		return

	for cell in source_layer.get_used_cells():
		var tile_pos := origin + cell

		var source_id := source_layer.get_cell_source_id(cell)
		var atlas_coords := source_layer.get_cell_atlas_coords(cell)
		var alt_id := source_layer.get_cell_alternative_tile(cell)

		if source_id == -1:
			continue

		var source := tile_set.get_source(source_id)
		if source == null or not (source is TileSetAtlasSource):
			continue

		var td := (source as TileSetAtlasSource).get_tile_data(atlas_coords, alt_id)
		if td == null:
			continue

		var block_id: int = td.get_custom_data("block_id")

		if block_id == -67:
			modify_tile(tile_pos, false)
			continue

		var block_data := BlockDatabase.get_block_by_id(block_id)
		if block_data == null:
			continue

		modified_tiles[tile_pos] = block_id

		tilemap.set_cell(tile_pos, source_id, atlas_coords, alt_id)

#--------------------------------------------------------#
# HELPER FUNCTIONS
#--------------------------------------------------------#

## Finds the TileMapLayer of a specific node. Used mainly in helper functions.
func _find_tilemap_layer(node: Node) -> TileMapLayer:
	if node is TileMapLayer:
		return node
	for child in node.get_children():
		var result := _find_tilemap_layer(child)
		if result:
			return result
	return null

## Returns the TileMapLayer of a packedScene following my structure template.
func _get_structure_layer(scene: PackedScene) -> TileMapLayer:
	var instance := scene.instantiate()
	if instance is TileMapLayer:
		return instance

	var found := _find_tilemap_layer(instance)
	if found == null:
		instance.queue_free()
	return found

## Gets which layer a chunk belongs to, using the chunk's center.
func _get_layer_for_chunk(chunk_x: int, chunk_y: int) -> LayerData:
	var center_tile_y = chunk_y * GameSettings.chunk_size + (GameSettings.chunk_size / 2)
	return LayerDatabase.get_layer_for_position(Vector2(chunk_x * GameSettings.chunk_size, center_tile_y))

## Returns the noise generator for a layer, creating + seeding it on first use.
func _get_noise_for_layer(layer: LayerData) -> FastNoiseLite:
	if layer == null:
		return _fallback_noise

	if _layer_noise_cache.has(layer.layer_id):
		return _layer_noise_cache[layer.layer_id]

	var noise := FastNoiseLite.new()
	noise.seed = GameSettings.seed_
	noise.frequency = layer.noise_frequency
	noise.fractal_type = layer.noise_fractal_type
	_layer_noise_cache[layer.layer_id] = noise
	return noise
