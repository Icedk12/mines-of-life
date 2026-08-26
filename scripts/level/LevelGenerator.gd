class_name LevelGenerator extends Node

signal initial_generation_finished

@export var tilemap : LevelMap
@export var terrain_set_id : int = 0
@export var terrain_id : int = 0
@export var tile_generate_chance : float = 0.25 ## For perlin noise, less = more air and bigger caves

@export_group("Performance")
@export var tiles_per_frame_budget : int = 128
@export var ores_per_frame_budget : int = 4   ## how many ore TYPES to roll per frame
@export var lights_per_frame_budget : int = 128
@export var unload_chunks_per_frame : int = 1
@export var unload_buffer : int = 2
@export var unload_tiles_per_frame_budget : int = 128

@export_group("Structures")
@export var structures : Array[StructureDefinition] ## Each has its own scene + individual spawn_chance.

@onready var player = get_parent().get_parent().player as Player

var tile_damage : Dictionary[Vector2i, int] = {}

enum GenPhase { TILES, ORES, LIGHTS }
var _gen_phase : GenPhase = GenPhase.TILES

var _interior_atlas_cache : Dictionary = {}
var _gen_modified_by_terrain : Dictionary = {}

var _gen_paint_by_terrain : Dictionary = {}
var _gen_available_set : Dictionary = {}
var _gen_ore_index : int = 0

# structure cache
var _structure_cache : Dictionary = {}

var cave_noise : FastNoiseLite = FastNoiseLite.new()
var loaded_chunks := {}
var generation_queue : Array[Vector2i] = []
var unload_queue : Array[Vector2i] = []
var last_player_chunk := Vector2i(999999, 999999)

var modified_tiles := {}
var _placed_structures : Array = []

var is_generating : bool = false
var is_initial_generation : bool = true
var initial_generation_complete : bool = false

var _gen_active : bool = false
var _gen_start_x : int = 0
var _gen_start_y : int = 0
var _gen_x : int = 0
var _gen_y : int = 0
var _gen_tiles_to_place : Array[Vector2i] = []

var _unload_active : bool = false
var _unload_chunk_key : Vector2i
var _unload_x : int = 0
var _unload_y : int = 0

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	cave_noise.frequency = 0.03
	cave_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	
	_get_settings()
	
	for def : StructureDefinition in structures:
		if def and def.scene:
			_cache_structure(def.scene)

func _get_settings() -> void:
	if GameSettings:
		tiles_per_frame_budget = GameSettings.tiles_per_frame_budget
		ores_per_frame_budget = GameSettings.ores_per_frame_budget
		lights_per_frame_budget = GameSettings.lights_per_frame_budget
		unload_chunks_per_frame = GameSettings.unload_chunks_per_frame
		unload_buffer = GameSettings.unload_buffer
		unload_tiles_per_frame_budget = GameSettings.unload_tiles_per_frame_budget

func _get_structure_layer(scene: PackedScene) -> TileMapLayer:
	var instance := scene.instantiate()
	if instance is TileMapLayer:
		return instance

	var found := _find_tilemap_layer(instance)
	if found == null:
		instance.queue_free()
	return found

func _find_tilemap_layer(node: Node) -> TileMapLayer:
	if node is TileMapLayer:
		return node
	for child in node.get_children():
		var result := _find_tilemap_layer(child)
		if result:
			return result
	return null

func _generate_chunk_structures(chunk_x: int, chunk_y: int) -> void:
	if structures.is_empty():
		return

	for def : StructureDefinition in structures:
		if def == null or def.scene == null:
			continue
		if rng.randf() > def.spawn_chance:
			continue

		_place_structure(def, chunk_x, chunk_y)

func _place_structure(def: StructureDefinition, chunk_x: int, chunk_y: int) -> void:
	var scene := def.scene
	if not _structure_cache.has(scene):
		_cache_structure(scene)
	
	var data = _structure_cache[scene]
	if data == null:
		return

	var min_cell : Vector2i = data.min_cell
	var size : Vector2i = data.size

	var chunk_size := GameSettings.chunk_size
	var start_x := chunk_x * chunk_size
	var start_y := chunk_y * chunk_size

	var max_x = max(chunk_size - size.x, 0)
	var max_y = max(chunk_size - size.y, 0)
	
	for attempt in def.placement_attempts:
		var origin := Vector2i(
			start_x + rng.randi_range(0, max_x),
			start_y + rng.randi_range(0, max_y)
		) - min_cell

		var candidate_rect := Rect2i(origin, size)

		if _is_valid_placement(candidate_rect, def):
			_stamp_structure(data.cells, origin)
			_placed_structures.append({"rect": candidate_rect, "def": def})
			return

func _is_valid_placement(candidate_rect: Rect2i, def: StructureDefinition) -> bool:
	for placed in _placed_structures:
		
		var placed_rect : Rect2i = placed.rect
		if candidate_rect.intersects(placed_rect):
			return false
		
		if placed.def == def and def.min_spacing > 0:
			if placed_rect.grow(def.min_spacing).intersects(candidate_rect):
				return false
	return true

func _stamp_structure(cells: Array, origin: Vector2i) -> void:
	for entry in cells:
		var tile_pos : Vector2i = origin + entry.pos
		var block_id : int = entry.block_id

		if block_id == -67:
			modify_tile(tile_pos, false)
			continue

		var block_data := BlockDatabase.get_block_by_id(block_id)
		if block_data == null:
			continue

		modified_tiles[tile_pos] = block_id

func _generate_chunk_ores(tiles : Array[Vector2i]) -> void:
	if tiles.is_empty():
		return

	var available_set : Dictionary = {}
	for t in tiles:
		available_set[t] = true

	for ore_type : BlockSetting in GenerationSettings.ores:
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

		tilemap.set_cells_terrain_connect(vein, bd.terrain_set_id, bd.terrain_id)

func generate_initial_world() -> void:
	cave_noise.seed = GameSettings.seed_
	rng.seed = GameSettings.seed_ # Seed structure/ore RNG so results are consistent per-seed
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

func _process(_delta: float) -> void:
	if not is_generating:
		return

	if _gen_active:
		_get_settings()
		match _gen_phase:
			GenPhase.TILES:
				_step_chunk_generation()
			GenPhase.ORES:
				_step_ore_generation()
			GenPhase.LIGHTS:
				_step_light_phase()
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
	_generate_chunk_structures(chunk_x, chunk_y)

	_gen_active = true
	_gen_phase = GenPhase.TILES
	_gen_start_x = chunk_x * GameSettings.chunk_size
	_gen_start_y = chunk_y * GameSettings.chunk_size
	_gen_x = 0
	_gen_y = 0
	_gen_tiles_to_place.clear()
	_gen_paint_by_terrain.clear()

func _step_chunk_generation() -> void:
	var processed := 0
	var chunk_size := GameSettings.chunk_size

	while _gen_y < chunk_size:
		while _gen_x < chunk_size:
			if processed >= tiles_per_frame_budget:
				return

			var x := _gen_start_x + _gen_x
			var y := _gen_start_y + _gen_y
			var tile_pos := Vector2i(x, y)

			if modified_tiles.has(tile_pos):
				var stored_id = modified_tiles[tile_pos]
				if stored_id != -1:
					var bd := BlockDatabase.get_block_by_id(stored_id)
					if bd:
						var key := Vector2i(bd.terrain_set_id, bd.terrain_id)
						if not _gen_paint_by_terrain.has(key):
							_gen_paint_by_terrain[key] = [] as Array[Vector2i]
						_gen_paint_by_terrain[key].append(tile_pos)
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

	_finish_tile_scan()

func _finish_tile_scan() -> void:
	_gen_available_set.clear()
	for t in _gen_tiles_to_place:
		_gen_available_set[t] = true
	_gen_ore_index = 0
	_gen_phase = GenPhase.ORES

func _finish_chunk_generation() -> void:
	_gen_active = false
	_gen_tiles_to_place = []
	_gen_paint_by_terrain.clear()

func _step_unload_queue() -> void:
	if not _unload_active:
		if unload_queue.is_empty():
			return
		_unload_chunk_key = unload_queue.pop_front()
		tilemap.unload_chunk_lights(_unload_chunk_key.x, _unload_chunk_key.y)
		_unload_active = true
		_unload_x = 0
		_unload_y = 0

	var start_x := _unload_chunk_key.x * GameSettings.chunk_size
	var start_y := _unload_chunk_key.y * GameSettings.chunk_size
	var processed := 0
	var chunk_size := GameSettings.chunk_size

	while _unload_y < chunk_size:
		while _unload_x < chunk_size:
			if processed >= unload_tiles_per_frame_budget:
				return
			tilemap.erase_cell(Vector2i(start_x + _unload_x, start_y + _unload_y))
			processed += 1
			_unload_x += 1
		_unload_x = 0
		_unload_y += 1

	_unload_active = false

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

func _cache_structure(scene: PackedScene) -> void:
	if _structure_cache.has(scene):
		return

	var layer := _get_structure_layer(scene)
	if layer == null:
		_structure_cache[scene] = null
		return

	var used_cells := layer.get_used_cells()
	if used_cells.is_empty():
		layer.queue_free()
		_structure_cache[scene] = null
		return

	var tile_set := layer.tile_set
	var cells : Array = []
	var min_cell := used_cells[0]
	var max_cell := used_cells[0]

	for cell in used_cells:
		min_cell = Vector2i(min(min_cell.x, cell.x), min(min_cell.y, cell.y))
		max_cell = Vector2i(max(max_cell.x, cell.x), max(max_cell.y, cell.y))

		var source_id := layer.get_cell_source_id(cell)
		var atlas_coords := layer.get_cell_atlas_coords(cell)
		var alt_id := layer.get_cell_alternative_tile(cell)

		var source := tile_set.get_source(source_id) if tile_set else null
		if source == null or not (source is TileSetAtlasSource):
			continue

		var td : TileData = (source as TileSetAtlasSource).get_tile_data(atlas_coords, alt_id)
		if td == null:
			continue

		cells.append({"pos": cell, "block_id": td.get_custom_data("block_id")})

	layer.queue_free()

	_structure_cache[scene] = {
		"cells": cells,
		"min_cell": min_cell,
		"size": (max_cell - min_cell) + Vector2i.ONE,
	}

func _begin_light_phase() -> void:
	_gen_phase = GenPhase.LIGHTS
	if tilemap.begin_chunk_lights(_gen_start_x / GameSettings.chunk_size, _gen_start_y / GameSettings.chunk_size):
		_finish_chunk_generation()

func _step_light_phase() -> void:
	if tilemap.step_chunk_lights(lights_per_frame_budget):
		_finish_chunk_generation()

func _begin_ore_phase() -> void:
	_gen_available_set.clear()
	for t in _gen_tiles_to_place:
		_gen_available_set[t] = true
	_gen_ore_index = 0
	_gen_phase = GenPhase.ORES

func _step_ore_generation() -> void:
	var ores := GenerationSettings.ores
	var processed := 0

	while _gen_ore_index < ores.size():
		if processed >= ores_per_frame_budget:
			return

		var ore_type : BlockSetting = ores[_gen_ore_index]
		_gen_ore_index += 1
		processed += 1

		if rng.randf() > ore_type.gen_chance:
			continue

		var vein : Array[Vector2i]
		if ore_type.shape_type == BlockSetting.ShapeType.PENNY_BLOCK:
			vein = _grow_penny_vein(ore_type.min_size, ore_type.max_size, _gen_available_set)
		else:
			vein = _grow_vein(rng.randi_range(ore_type.min_size, ore_type.max_size), _gen_available_set)

		if vein.is_empty():
			continue

		var bd := BlockDatabase.get_block_by_id(ore_type.block_id)
		if bd == null:
			continue

		var key := Vector2i(bd.terrain_set_id, bd.terrain_id)
		if not _gen_paint_by_terrain.has(key):
			_gen_paint_by_terrain[key] = [] as Array[Vector2i]

		for pos in vein:
			modified_tiles[pos] = ore_type.block_id
			_gen_available_set.erase(pos) # claim it — won't be painted as base terrain
			_gen_paint_by_terrain[key].append(pos)

	_finish_generation_paint()

## Paint all terrain at once
func _finish_generation_paint() -> void:
	if not _gen_available_set.is_empty():
		var interior_cells : Array[Vector2i] = []
		var edge_cells : Array[Vector2i] = []
		var chunk_size := GameSettings.chunk_size

		for pos in _gen_available_set.keys():
			var local_x = pos.x - _gen_start_x
			var local_y = pos.y - _gen_start_y
			var on_chunk_border = local_x == 0 or local_y == 0 or local_x == chunk_size - 1 or local_y == chunk_size - 1

			if not on_chunk_border and _is_interior_cell(pos):
				interior_cells.append(pos)
			else:
				edge_cells.append(pos)

		if not interior_cells.is_empty():
			var baked := _bake_interior_tile(terrain_set_id, terrain_id)
			for pos in interior_cells:
				tilemap.set_cell(pos, baked.source_id, baked.atlas_coords, baked.alt_id)

		if not edge_cells.is_empty():
			tilemap.set_cells_terrain_connect(edge_cells, terrain_set_id, terrain_id)

	for key : Vector2i in _gen_paint_by_terrain.keys():
		tilemap.set_cells_terrain_connect(_gen_paint_by_terrain[key], key.x, key.y)

	_gen_paint_by_terrain.clear()
	_gen_available_set.clear()

	_begin_light_phase()

func _bake_interior_tile(terrain_set: int, terrain: int) -> Dictionary:
	var key := Vector2i(terrain_set, terrain)
	if _interior_atlas_cache.has(key):
		return _interior_atlas_cache[key]

	var scratch := TileMapLayer.new()
	scratch.tile_set = tilemap.tile_set
	add_child(scratch)

	var block : Array[Vector2i] = []
	for x in range(5):
		for y in range(5):
			block.append(Vector2i(x, y))
	scratch.set_cells_terrain_connect(block, terrain_set, terrain)

	var center := Vector2i(2, 2) # dead center of a solid 5x5 block = guaranteed fully-interior variant
	var result := {
		"source_id": scratch.get_cell_source_id(center),
		"atlas_coords": scratch.get_cell_atlas_coords(center),
		"alt_id": scratch.get_cell_alternative_tile(center),
	}

	scratch.queue_free()
	_interior_atlas_cache[key] = result
	return result

func _is_plain_cave_fill(pos: Vector2i) -> bool:
	if modified_tiles.has(pos):
		return false # ore/structure/dug-out here — not uniform base terrain, don't treat as interior filler
	return cave_noise.get_noise_2d(pos.x, pos.y) <= tile_generate_chance

func _is_interior_cell(pos: Vector2i) -> bool:
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			if not _is_plain_cave_fill(pos + Vector2i(dx, dy)):
				return false
	return true
