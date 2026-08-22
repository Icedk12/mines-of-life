class_name MineComponent
extends CharacterComponent

@export_group("Components")
@export var inventory_component : InventoryComponent
@export var selection_component : SelectionBoxComponent
@export var camera : ShakeableCamera2D
@export var audio_source : AudioSourceComponent

@export_group("Mining")
@export var max_mining_distance : float = 40.0
@export var mine_strength : int = 1
@export var hit_amount : int = 1
@export var tile_damage_component : TileDamageComponent
@export var cd_timer : Timer

var level_generator : LevelGenerator

func _process(_delta: float) -> void:
	update_selection()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			if mine():
				get_viewport().set_input_as_handled()

func update_selection() -> void:
	if not level_generator and character and character.level:
		level_generator = character.level.level_generator

	if not level_generator or not level_generator.tilemap:
		return

	var mouse_pos = character.get_global_mouse_position()
	
	# Cursor
	var tile_pos = level_generator.tilemap.local_to_map(mouse_pos)
	selection_component.selected_tile_global_pos = level_generator.tilemap.to_global(tile_pos * 8) + Vector2(4, 4)

func mine() -> bool:
	# Check if the cooldown timer is actively running
	if cd_timer and cd_timer.time_left > 0:
		return false

	if not level_generator or not level_generator.tilemap:
		return false

	var mouse_pos = character.get_global_mouse_position()
	if character.global_position.distance_to(mouse_pos) > max_mining_distance:
		return false

	var tile_pos = level_generator.tilemap.local_to_map(mouse_pos)
	if level_generator.tilemap.get_cell_source_id(tile_pos) == -1:
		return false

	var result = level_generator.damage_tile(tile_pos, hit_amount, mine_strength)
	if result.is_empty() or result.get("blocked", false):
		return false

	if result.get("broken", false):
		if inventory_component and result.block_id != -1:
			inventory_component.add_item_by_id(result.block_id)
		if tile_damage_component:
			tile_damage_component.clear()
		if audio_source:
			audio_source.play_sound(result.block_data.hit_sounds)
	else:
		if tile_damage_component:
			tile_damage_component.play_hit(tile_pos, result.hits, result.max_hits, result.block_data)
		if audio_source:
			audio_source.play_sound(result.block_data.hit_sounds)

	camera.add_trauma(0.15)
	camera.shake()
	if cd_timer:
		cd_timer.start()

	return true
