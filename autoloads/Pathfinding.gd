class_name TilePathfinder

static func find_path(
	tilemap: TileMapLayer,
	start_tile: Vector2i,
	goal_tile: Vector2i,
	padding: int,
	flying: bool,
	max_jump_height: int
) -> PackedVector2Array:
	var astar := AStar2D.new()
	var id_of : Dictionary = {}

	var min_x = min(start_tile.x, goal_tile.x) - padding
	var max_x = max(start_tile.x, goal_tile.x) + padding
	var min_y = min(start_tile.y, goal_tile.y) - padding
	var max_y = max(start_tile.y, goal_tile.y) + padding

	var next_id := 0
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var pos := Vector2i(x, y)
			if _is_open(tilemap, pos):
				id_of[pos] = next_id
				astar.add_point(next_id, Vector2(pos))
				next_id += 1

	if not id_of.has(start_tile) or not id_of.has(goal_tile):
		return PackedVector2Array() # no connected path visible in this window

	var dirs : Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	if flying:
		dirs.append_array([Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)])

	for pos in id_of.keys():
		for dir in dirs:
			var neighbor : Vector2i = pos + dir
			if not id_of.has(neighbor):
				continue
			if not flying and not _ground_reachable(tilemap, pos, neighbor, max_jump_height):
				continue
			var a : int = id_of[pos]
			var b : int = id_of[neighbor]
			if not astar.are_points_connected(a, b):
				astar.connect_points(a, b)

	var id_path := astar.get_point_path(id_of[start_tile], id_of[goal_tile])
	var world_path : PackedVector2Array = []
	for p in id_path:
		world_path.append(tilemap.to_global(tilemap.map_to_local(Vector2i(p))))
	return world_path

static func _is_open(tilemap: TileMapLayer, pos: Vector2i) -> bool:
	return tilemap.get_cell_source_id(pos) == -1

static func _ground_reachable(tilemap: TileMapLayer, from: Vector2i, to: Vector2i, max_jump: int) -> bool:
	var dy := to.y - from.y
	if dy < 0 and abs(dy) > max_jump:
		return false
	if dy < 0 and _is_open(tilemap, from + Vector2i.DOWN):
		return false # can't jump if not standing on something
	return true
