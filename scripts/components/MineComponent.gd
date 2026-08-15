class_name MineComponent extends CharacterComponent

@export var ray : RayCast2D
@export var max_mining_distance : float = 120.0

var level_generator : LevelGenerator

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			mine()

func mine() -> void:
	if not ray:
		return

	# Ensure we have a reference to the level generator
	if not level_generator and character and character.level:
		level_generator = character.level.level_generator

	# Convert global mouse position to local ray coordinates
	var global_mouse_pos = ray.get_global_mouse_position()
	var local_target = ray.to_local(global_mouse_pos)
	
	ray.target_position = local_target.limit_length(max_mining_distance)
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var hit_collider = ray.get_collider()
		
		# Ensure we hit the tilemap
		if hit_collider == level_generator.tilemap:
			var hit_point = ray.get_collision_point()
			var hit_normal = ray.get_collision_normal()
			
			# Nudge the hit point slightly inside the tile face
			var inside_tile_point = hit_point - (hit_normal * 2.0)
			
			# Convert world position to tile map coordinates
			var tile_pos = level_generator.tilemap.local_to_map(inside_tile_point)
			
			# Mine tile (sets modified_tiles to false and erases cell from tilemap)
			level_generator.modify_tile(tile_pos, false)
