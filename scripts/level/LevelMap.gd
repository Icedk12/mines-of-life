class_name LevelMap extends TileMapLayer

@export var light_scene: PackedScene
@export var target_terrain_set: int = 0
@export var target_terrain: int = 7
@export_group("Light Overlap")
@export var min_light_spacing: float = 24.0
@export var light_blend_mode: Light2D.BlendMode = Light2D.BLEND_MODE_MIX

var _light_gen_chunk_key : Vector2i
var _light_gen_start_x : int
var _light_gen_start_y : int
var _light_gen_x : int = 0
var _light_gen_y : int = 0
var _light_gen_lights_in_chunk : Dictionary = {}
var _light_gen_active : bool = false

var chunk_lights: Dictionary = {} # Vector2i(chunk) -> Dictionary[Vector2i(cell), Node2D]

func spawn_light_at(cell: Vector2i) -> void:
	var tile_data: TileData = get_cell_tile_data(cell)
	if not tile_data or tile_data.terrain_set != target_terrain_set or tile_data.terrain != target_terrain:
		remove_light_at(cell) # tile changed to something else — clear any stale light here
		return

	var chunk_key := _chunk_key_for_cell(cell)
	var lights_in_chunk : Dictionary = chunk_lights.get(chunk_key, {})

	if lights_in_chunk.has(cell):
		return # already lit

	var world_pos := map_to_local(cell)
	if _has_nearby_light(world_pos):
		return

	var light := _spawn_light(world_pos)
	lights_in_chunk[cell] = light
	chunk_lights[chunk_key] = lights_in_chunk

func remove_light_at(cell: Vector2i) -> void:
	var chunk_key := _chunk_key_for_cell(cell)
	if not chunk_lights.has(chunk_key):
		return

	var lights_in_chunk : Dictionary = chunk_lights[chunk_key]
	if not lights_in_chunk.has(cell):
		return

	var light = lights_in_chunk[cell]
	if is_instance_valid(light):
		light.queue_free()
	lights_in_chunk.erase(cell)

	if lights_in_chunk.is_empty():
		chunk_lights.erase(chunk_key)

func spawn_chunk_lights(chunk_x: int, chunk_y: int) -> void:
	var chunk_key := Vector2i(chunk_x, chunk_y)
	if chunk_lights.has(chunk_key):
		return

	var start_x = chunk_x * GameSettings.chunk_size
	var start_y = chunk_y * GameSettings.chunk_size
	var lights_in_chunk : Dictionary = {}

	for x in range(start_x, start_x + GameSettings.chunk_size):
		for y in range(start_y, start_y + GameSettings.chunk_size):
			var cell := Vector2i(x, y)
			var tile_data: TileData = get_cell_tile_data(cell)

			if tile_data and tile_data.terrain_set == target_terrain_set and tile_data.terrain == target_terrain:
				var world_pos := map_to_local(cell)
				if _has_nearby_light(world_pos, lights_in_chunk.values()):
					continue
				lights_in_chunk[cell] = _spawn_light(world_pos)

	if not lights_in_chunk.is_empty():
		chunk_lights[chunk_key] = lights_in_chunk

func unload_chunk_lights(chunk_x: int, chunk_y: int) -> void:
	var chunk_key := Vector2i(chunk_x, chunk_y)
	if chunk_lights.has(chunk_key):
		for light in chunk_lights[chunk_key].values():
			if is_instance_valid(light):
				light.queue_free()
		chunk_lights.erase(chunk_key)

func reload_chunk_lights(chunk_x: int, chunk_y: int) -> void:
	unload_chunk_lights(chunk_x, chunk_y)
	spawn_chunk_lights(chunk_x, chunk_y)

## ---- Helpers ----

func _chunk_key_for_cell(cell: Vector2i) -> Vector2i:
	return Vector2i(
		int(floor(float(cell.x) / GameSettings.chunk_size)),
		int(floor(float(cell.y) / GameSettings.chunk_size))
	)

func _spawn_light(world_pos: Vector2) -> Node2D:
	var light := light_scene.instantiate() as Node2D
	add_child(light)
	light.position = world_pos

	var light2d := _find_light2d(light)
	if light2d:
		light2d.blend_mode = light_blend_mode

	return light

func _find_light2d(node: Node) -> Light2D:
	if node is Light2D:
		return node
	for child in node.get_children():
		var found := _find_light2d(child)
		if found:
			return found
	return null

func _has_nearby_light(world_pos: Vector2, extra_candidates: Array = []) -> bool:
	var cell := local_to_map(world_pos)
	var center_chunk := _chunk_key_for_cell(cell)

	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var key := center_chunk + Vector2i(dx, dy)
			if not chunk_lights.has(key):
				continue
			for light in chunk_lights[key].values():
				if is_instance_valid(light) and light.position.distance_to(world_pos) < min_light_spacing:
					return true

	for light in extra_candidates:
		if is_instance_valid(light) and light.position.distance_to(world_pos) < min_light_spacing:
			return true
	return false

func begin_chunk_lights(chunk_x: int, chunk_y: int) -> bool:
	var chunk_key := Vector2i(chunk_x, chunk_y)
	if chunk_lights.has(chunk_key):
		return true

	_light_gen_chunk_key = chunk_key
	_light_gen_start_x = chunk_x * GameSettings.chunk_size
	_light_gen_start_y = chunk_y * GameSettings.chunk_size
	_light_gen_x = 0
	_light_gen_y = 0
	_light_gen_lights_in_chunk = {}
	_light_gen_active = true
	return false

func step_chunk_lights(budget: int) -> bool:
	if not _light_gen_active:
		return true

	var chunk_size := GameSettings.chunk_size
	var processed := 0

	while _light_gen_y < chunk_size:
		while _light_gen_x < chunk_size:
			if processed >= budget:
				return false # pick up here next frame

			var cell := Vector2i(_light_gen_start_x + _light_gen_x, _light_gen_start_y + _light_gen_y)
			var tile_data : TileData = get_cell_tile_data(cell)

			if tile_data and tile_data.terrain_set == target_terrain_set and tile_data.terrain == target_terrain:
				var world_pos := map_to_local(cell)
				if not _has_nearby_light(world_pos, _light_gen_lights_in_chunk.values()):
					_light_gen_lights_in_chunk[cell] = _spawn_light(world_pos)

			processed += 1
			_light_gen_x += 1

		_light_gen_x = 0
		_light_gen_y += 1

	if not _light_gen_lights_in_chunk.is_empty():
		chunk_lights[_light_gen_chunk_key] = _light_gen_lights_in_chunk

	_light_gen_active = false
	return true
