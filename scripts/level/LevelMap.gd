class_name LevelMap extends TileMapLayer

#--------------------------------------------------------#
# @export
#--------------------------------------------------------#

@export var light_scene: PackedScene
@export var target_terrain_set: int = 0
@export var target_terrain: int = 7
@export_group("Light Overlap")
@export var min_light_spacing: float = 24.0
@export var light_blend_mode: Light2D.BlendMode = Light2D.BLEND_MODE_MIX

#--------------------------------------------------------#
# LIGHT VARIABLES
#--------------------------------------------------------#

var _light_gen_chunk_key : Vector2i
var _light_gen_start_x : int
var _light_gen_start_y : int
var _light_gen_x : int = 0
var _light_gen_y : int = 0
var _light_gen_lights_in_chunk : Dictionary = {}
var _light_gen_active : bool = false

var chunk_lights: Dictionary = {}

#--------------------------------------------------------#
# CUSTOM BITMASK NOT AUTHORED BY ME - COLLATED FROM MULTIPLE SOURCES ONLINE
#--------------------------------------------------------#

const N_TOP          = 1
const N_TOP_RIGHT     = 2
const N_RIGHT         = 4
const N_BOTTOM_RIGHT  = 8
const N_BOTTOM        = 16
const N_BOTTOM_LEFT   = 32
const N_LEFT          = 64
const N_TOP_LEFT      = 128

const _NEIGHBOR_ORDER := [
	{ "bit": N_TOP,          "peer": TileSet.CELL_NEIGHBOR_TOP_SIDE },
	{ "bit": N_TOP_RIGHT,    "peer": TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,    "req": N_TOP | N_RIGHT },
	{ "bit": N_RIGHT,        "peer": TileSet.CELL_NEIGHBOR_RIGHT_SIDE },
	{ "bit": N_BOTTOM_RIGHT, "peer": TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, "req": N_BOTTOM | N_RIGHT },
	{ "bit": N_BOTTOM,       "peer": TileSet.CELL_NEIGHBOR_BOTTOM_SIDE },
	{ "bit": N_BOTTOM_LEFT,  "peer": TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,  "req": N_BOTTOM | N_LEFT },
	{ "bit": N_LEFT,         "peer": TileSet.CELL_NEIGHBOR_LEFT_SIDE },
	{ "bit": N_TOP_LEFT,     "peer": TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,     "req": N_TOP | N_LEFT },
]

const _NEIGHBOR_OFFSETS := [
	Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1),
]
const _NEIGHBOR_BITS := [N_TOP, N_TOP_RIGHT, N_RIGHT, N_BOTTOM_RIGHT, N_BOTTOM, N_BOTTOM_LEFT, N_LEFT, N_TOP_LEFT]

var _terrain_lookup : Dictionary = {}
var _terrain_lookup_built : bool = false
var _non_connecting_terrains : Dictionary = {}

func _build_terrain_lookup() -> void:
	_terrain_lookup.clear()
	_non_connecting_terrains.clear()
	_terrain_lookup_built = true

	if tile_set == null:
		return
	var source := tile_set.get_source(0) as TileSetAtlasSource
	if source == null:
		return

	for i in source.get_tiles_count():
		var atlas_coord : Vector2i = source.get_tile_id(i)
		var td : TileData = source.get_tile_data(atlas_coord, 0)
		if td == null or td.terrain_set != 0 or td.terrain < 0:
			continue

		var mask := 0
		for entry in _NEIGHBOR_ORDER:
			if td.get_terrain_peering_bit(entry.peer) != -1:
				mask |= entry.bit

		if not _terrain_lookup.has(td.terrain):
			_terrain_lookup[td.terrain] = {}
		if not _terrain_lookup[td.terrain].has(mask):
			_terrain_lookup[td.terrain][mask] = atlas_coord

	for terrain_index in _terrain_lookup.keys():
		var table : Dictionary = _terrain_lookup[terrain_index]
		if table.size() == 1 and table.has(0):
			_non_connecting_terrains[terrain_index] = true

func _get_atlas_coord(terrain_index: int, mask: int) -> Vector2i:
	if not _terrain_lookup_built:
		_build_terrain_lookup()

	var table : Dictionary = _terrain_lookup.get(terrain_index, {})
	if table.is_empty():
		return Vector2i.ZERO

	var clean_mask := mask
	for entry in _NEIGHBOR_ORDER:
		if entry.has("req") and (clean_mask & entry.bit) != 0 and (clean_mask & entry.req) != entry.req:
			clean_mask &= ~entry.bit

	if table.has(clean_mask):
		return table[clean_mask]

	var side_bits := N_TOP | N_RIGHT | N_BOTTOM | N_LEFT
	var best_key : int = -1
	var best_score : int = -999999
	for key in table.keys():
		var diff : int = clean_mask ^ key
		var side_diff := diff & side_bits
		var corner_diff := diff & ~side_bits
		var primary := _popcount(side_diff) * 4 + _popcount(corner_diff)
		var score := -(primary * 16 + _popcount(key))
		if score > best_score:
			best_score = score
			best_key = key

	if best_key != -1:
		return table[best_key]

	return Vector2i.ZERO

func _popcount(v: int) -> int:
	var c := 0
	while v != 0:
		c += v & 1
		v >>= 1
	return c

func _compute_neighbor_mask(cell: Vector2i, all_solid_cells: Dictionary) -> int:
	var mask := 0
	for j in _NEIGHBOR_OFFSETS.size():
		if _is_solid(cell + _NEIGHBOR_OFFSETS[j], all_solid_cells):
			mask |= _NEIGHBOR_BITS[j]
	return mask

func _compute_neighbor_mask_from_map(cell: Vector2i) -> int:
	var mask := 0
	for j in _NEIGHBOR_OFFSETS.size():
		if _is_solid_on_map(cell + _NEIGHBOR_OFFSETS[j]):
			mask |= _NEIGHBOR_BITS[j]
	return mask

func set_cells(coords_array: Array[Vector2i], source_id: int = -1, atlas_coords: Vector2i = Vector2i(-1, -1), alternative_tile: int = 0) -> void:
	for cell_pos in coords_array:
		set_cell(cell_pos, source_id, atlas_coords, alternative_tile)

func custom_terrain_connect(cells_to_place: Array, source_id: int, all_solid_cells: Dictionary, terrain_index: int = 0) -> void:
	for cell in cells_to_place:
		var mask := _compute_neighbor_mask(cell, all_solid_cells)
		var atlas_coord := _get_atlas_coord(terrain_index, mask)
		set_cell(cell, source_id, atlas_coord)

func refresh_cell(cell: Vector2i) -> void:
	var source_id := get_cell_source_id(cell)
	if source_id == -1:
		return
	var td := get_cell_tile_data(cell)
	if td == null:
		return
	var mask := _compute_neighbor_mask_from_map(cell)
	set_cell(cell, source_id, _get_atlas_coord(td.terrain, mask))

func refresh_cells(cells: Array[Vector2i]) -> void:
	for c in cells:
		refresh_cell(c)

## Places/erases a single tile, then re-evaluates it and all 8 neighbors
func update_single_tile_and_neighbors(cell: Vector2i, source_id: int, terrain_index: int = 0, is_erasing: bool = false) -> void:
	if is_erasing:
		set_cell(cell, -1)
	else:
		var mask := _compute_neighbor_mask_from_map(cell)
		set_cell(cell, source_id, _get_atlas_coord(terrain_index, mask))

	var cells_to_update : Array[Vector2i] = [cell]
	for off in _NEIGHBOR_OFFSETS:
		cells_to_update.append(cell + off)

	for c in cells_to_update:
		var current_source := get_cell_source_id(c)
		if current_source == -1:
			continue

		var td := get_cell_tile_data(c)
		if td == null:
			continue

		var n_terrain_index : int = td.terrain
		var n_mask := _compute_neighbor_mask_from_map(c)
		set_cell(c, current_source, _get_atlas_coord(n_terrain_index, n_mask))

func terrain_connects(terrain_index: int) -> bool:
	if not _terrain_lookup_built:
		_build_terrain_lookup()
	return not _non_connecting_terrains.has(terrain_index)

func _is_solid_on_map(cell: Vector2i) -> bool:
	var source_id := get_cell_source_id(cell)
	if source_id == -1:
		return false
	var td := get_cell_tile_data(cell)
	if td != null and _non_connecting_terrains.has(td.terrain):
		return false
	return true

#--------------------------------------------------------#
# LIGHT FUNCTIONS
#--------------------------------------------------------#

func spawn_light_at(cell: Vector2i) -> void:
	var tile_data: TileData = get_cell_tile_data(cell)
	if not tile_data or tile_data.terrain_set != target_terrain_set or tile_data.terrain != target_terrain:
		remove_light_at(cell)
		return

	var chunk_key := _chunk_key_for_cell(cell)
	var lights_in_chunk : Dictionary = chunk_lights.get(chunk_key, {})

	if lights_in_chunk.has(cell):
		return

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

#--------------------------------------------------------#
# HELPERS
#--------------------------------------------------------#

func _is_solid(cell: Vector2i, current_chunk_solids: Dictionary) -> bool:
	if current_chunk_solids.has(cell):
		return true
	return _is_solid_on_map(cell)

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
				return false

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
