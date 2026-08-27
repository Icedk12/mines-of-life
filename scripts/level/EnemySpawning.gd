class_name EnemySpawner extends Node

@export_group("References")
@export var level_generator : LevelGenerator
@export var player : Player

@export_group("Enemies")
@export var enemy_scenes : Array[PackedScene]

@export_group("Timing")
@export var spawn_interval : float = 5.0
@export var spawn_attempts_per_cycle : int = 20 ## random tile candidates tried before giving up

@export_group("Distance (world units)")
@export var min_spawn_distance : float = 80.0
@export var max_spawn_distance : float = 220.0

@export_group("Limits")
@export var max_alive_enemies : int = 12

@export_group("Despawning")
@export var despawn_buffer_tiles : int = 4 ## extra chunks of slack beyond loaded_chunks before despawning
@export var despawn_check_interval : float = 2.0

var _despawn_timer : float = 0.0


var rng := RandomNumberGenerator.new()

@onready var timer : Timer = $Timer

func _ready() -> void:
	rng.randomize()
	timer.wait_time = spawn_interval
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _process(delta: float) -> void:
	_despawn_timer -= delta
	if _despawn_timer <= 0.0:
		_despawn_timer = despawn_check_interval
		_despawn_far_enemies()

func _despawn_far_enemies() -> void:
	if level_generator == null or level_generator.tilemap == null or player == null:
		return

	var tilemap := level_generator.tilemap
	var player_tile := tilemap.local_to_map(tilemap.to_local(player.global_position))
	var player_chunk := Vector2i(
		int(floor(float(player_tile.x) / GameSettings.chunk_size)),
		int(floor(float(player_tile.y) / GameSettings.chunk_size))
	)

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue

		var enemy_tile := tilemap.local_to_map(tilemap.to_local(enemy.global_position))
		var enemy_chunk := Vector2i(
			int(floor(float(enemy_tile.x) / GameSettings.chunk_size)),
			int(floor(float(enemy_tile.y) / GameSettings.chunk_size))
		)

		var dist_x = abs(enemy_chunk.x - player_chunk.x)
		var dist_y = abs(enemy_chunk.y - player_chunk.y)
		var limit := GameSettings.render_distance + despawn_buffer_tiles

		if dist_x > limit or dist_y > limit:
			enemy.queue_free()

func _on_timer_timeout() -> void:
	if not _can_spawn():
		return
	_try_spawn_one()

func _can_spawn() -> bool:
	if enemy_scenes == null or level_generator == null or player == null:
		return false
	if not level_generator.initial_generation_complete:
		return false
	return get_tree().get_nodes_in_group("enemies").size() < max_alive_enemies

func _try_spawn_one() -> void:
	var tilemap := level_generator.tilemap
	if tilemap == null:
		return
	
	for i in spawn_attempts_per_cycle:
		var angle := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(min_spawn_distance, max_spawn_distance)
		var world_pos : Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * dist

		var tile_pos := tilemap.local_to_map(world_pos)
		if not _is_valid_spawn_tile(tile_pos):
			continue

		_spawn_enemy(tilemap.to_global(tilemap.map_to_local(tile_pos)))
		return # spawned one = done

func _is_valid_spawn_tile(tile_pos : Vector2i) -> bool:
	var tilemap := level_generator.tilemap

	# Must be inside a chunk thats actually been generated
	var chunk_key := Vector2i(
		int(floor(float(tile_pos.x) / GameSettings.chunk_size)),
		int(floor(float(tile_pos.y) / GameSettings.chunk_size))
	)
	if not level_generator.loaded_chunks.has(chunk_key):
		return false

	# spawn in ari
	if tilemap.get_cell_source_id(tile_pos) != -1:
		return false
	return true

func _spawn_enemy(world_pos : Vector2) -> void:
	var enemy = enemy_scenes.pick_random().instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = world_pos
	if enemy.has_method("setup"):
		enemy.setup(player, level_generator)
	print("Spawned enemy")
