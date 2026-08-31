class_name ChunkStorage


static func _save_dir(world_seed: int) -> String:
	return "user://world_saves/%d" % world_seed

static func _chunk_path(world_seed: int, chunk_key: Vector2i) -> String:
	return "%s/chunk_%d_%d.chunk" % [_save_dir(world_seed), chunk_key.x, chunk_key.y]

## true if this chunk has ever been generated & saved before
static func has_chunk(world_seed: int, chunk_key: Vector2i) -> bool:
	return FileAccess.file_exists(_chunk_path(world_seed, chunk_key))

## Loads a chunk's modified-tile deltas.
## [local tile coords] = block_id
static func load_chunk(world_seed: int, chunk_key: Vector2i) -> Dictionary:
	var path := _chunk_path(world_seed, chunk_key)
	if not FileAccess.file_exists(path):
		return {}

	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("ChunkStorage: failed to open %s for reading (err %d)" % [path, FileAccess.get_open_error()])
		return {}

	var data = f.get_var()
	f.close()
	return data if data is Dictionary else {}

## Saves a chunk's modified-tile deltas to disk. The file's mere existence is what marks the chunk as "already generated" so ore/structure generation doesn't reroll on the next visit.
## The tiles blend together but i would be lost without their chunks.
static func save_chunk(world_seed: int, chunk_key: Vector2i, local_modified_tiles: Dictionary) -> void:
	var dir := _save_dir(world_seed)
	var err := DirAccess.make_dir_recursive_absolute(dir)
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_warning("ChunkStorage: couldn't create save dir %s (err %d)" % [dir, err])
		return

	var f := FileAccess.open(_chunk_path(world_seed, chunk_key), FileAccess.WRITE)
	if f == null:
		push_warning("ChunkStorage: failed to open chunk %s for writing (err %d)" % [chunk_key, FileAccess.get_open_error()])
		return

	f.store_var(local_modified_tiles)
	f.close()

## Note: Every seed already generated counts as world, so if u do seed 6767 twice it will save.
## eventually wire it up so this is called on death or delete.
static func clear_world(world_seed: int) -> void:
	var dir_path := _save_dir(world_seed)
	if not DirAccess.dir_exists_absolute(dir_path):
		return

	var dir := DirAccess.open(dir_path)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			dir.remove(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
