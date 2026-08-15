class_name MineComponent extends CharacterComponent

@export var selection_component : SelectionBoxComponent
@export var ray : RayCast2D
@export var max_mining_distance : float = 40.0

var level_generator : LevelGenerator

func _process(_delta: float) -> void:
	update_selection()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			mine()

## Updates the raycast and selection cursor position to track the mouse
func update_selection() -> void:
	if not ray:
		return

	# Ensure we have a reference to the level generator
	if not level_generator and character and character.level:
		level_generator = character.level.level_generator

	if not level_generator or not level_generator.tilemap:
		return

	# Convert global mouse position to local ray coordinates
	var global_mouse_pos = ray.get_global_mouse_position()
	var local_target = ray.to_local(global_mouse_pos)
	
	ray.target_position = local_target.limit_length(max_mining_distance)
	ray.force_raycast_update()
	
	if ray.is_colliding() and ray.get_collider() == level_generator.tilemap:
		var hit_point = ray.get_collision_point()
		var hit_normal = ray.get_collision_normal()
		
		# Nudge the hit point slightly inside the tile face
		var inside_tile_point = hit_point - (hit_normal * 2.0)
		
		# Convert world position to tile map coordinates and set cursor position
		var tile_pos = level_generator.tilemap.local_to_map(inside_tile_point)
		selection_component.selected_tile_global_pos = level_generator.tilemap.to_global(tile_pos * 8) + Vector2(4, 4)
		
func mine() -> void:
	# Raycast is updated via update_selection() in process
	if ray and ray.is_colliding() and level_generator and level_generator.tilemap:
		if ray.get_collider() == level_generator.tilemap:
			var hit_point = ray.get_collision_point()
			var hit_normal = ray.get_collision_normal()
			var inside_tile_point = hit_point - (hit_normal * 2.0)
			var tile_pos = level_generator.tilemap.local_to_map(selection_component.selected_tile_global_pos)

			# Mine tile
			level_generator.modify_tile(tile_pos, false)
