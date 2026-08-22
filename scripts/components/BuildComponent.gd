class_name BuildComponent extends CharacterComponent

@export var inventory_component : InventoryComponent
@export var selection_component : SelectionBoxComponent
@export var max_build_distance : float = 40.0
@export var selected_block_id : int = 0

var level_generator : LevelGenerator

func _process(_delta: float) -> void:
	update_selection()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			if build():
				get_viewport().set_input_as_handled()

func update_selection() -> void:
	# Initialize level_generator reference from character
	if not level_generator and character and character.level:
		level_generator = character.level.level_generator

	if not level_generator or not level_generator.tilemap:
		return

	var mouse_pos = character.get_global_mouse_position()

	var tile_pos = level_generator.tilemap.local_to_map(mouse_pos)
	selection_component.selected_tile_global_pos = level_generator.tilemap.to_global(tile_pos * 8) + Vector2(4, 4)

func build() -> bool:
	if not level_generator or not level_generator.tilemap:
		return false

	var mouse_pos = character.get_global_mouse_position()
	var char_pos = character.global_position

	if char_pos.distance_to(mouse_pos) > max_build_distance:
		return false

	var tile_pos = level_generator.tilemap.local_to_map(mouse_pos)

	# Only build if space is currently empty (-1 source ID)
	if level_generator.tilemap.get_cell_source_id(tile_pos) != -1:
		return false

	# Verify inventory has the item before placing
	if inventory_component and inventory_component.has_item(selected_block_id):
		if inventory_component.remove_item_by_id(selected_block_id):
			level_generator.modify_tile(tile_pos, true, selected_block_id)
			return true
			
	return false
