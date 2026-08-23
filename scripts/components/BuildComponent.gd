class_name BuildComponent extends CharacterComponent

@export var inventory_component : InventoryComponent
@export var player_gui : PlayerGUI
@export var selection_component : SelectionBoxComponent
@export var max_build_distance : float = 40.0
@export var camera : Camera2D

@export_group("Audio")
@export var audio_source : AudioSourceComponent

var inventory_ui : InventoryUI
var level_generator : LevelGenerator

func _ready() -> void:
	inventory_ui = player_gui.inventory_ui

func _process(_delta: float) -> void:
	if not level_generator and character and character.level:
		level_generator = character.level.level_generator

	update_selection()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			if build():
				get_viewport().set_input_as_handled()

func update_selection() -> void:
	if not level_generator or not level_generator.tilemap:
		return

	var mouse_pos = character.get_global_mouse_position()
	var tile_pos = level_generator.tilemap.local_to_map(mouse_pos)
	selection_component.selected_tile_global_pos = level_generator.tilemap.to_global(tile_pos * 8) + Vector2(4, 4)

func _get_selected_item_id() -> int:
	if not inventory_component or not inventory_ui:
		return -1
	var item_id := inventory_ui.get_selected_item_id()
	if item_id == -1 or not inventory_component.has_item(item_id):
		return -1
	return item_id

func _get_block_id_for_item(item_id: int) -> int:
	if item_id == -1:
		return -1
	var item := ItemDatabase.get_item_by_id(item_id)
	return item.block_id if item else -1

func build() -> bool:
	if not level_generator or not level_generator.tilemap:
		return false

	var selected_item_id := _get_selected_item_id()
	if selected_item_id == -1:
		return false

	var selected_block_id := _get_block_id_for_item(selected_item_id)
	if selected_block_id == -1:
		return false

	var mouse_pos = character.get_global_mouse_position()
	if character.global_position.distance_to(mouse_pos) > max_build_distance:
		return false

	var tile_pos = level_generator.tilemap.local_to_map(mouse_pos)
	if level_generator.tilemap.get_cell_source_id(tile_pos) != -1:
		return false

	if inventory_component.remove_item_by_id(selected_item_id):
		level_generator.modify_tile(tile_pos, true, selected_block_id)
		if audio_source:
			var block_data := BlockDatabase.get_block_by_id(selected_block_id)
			if block_data:
				audio_source.play_sound(block_data.place_sounds)
		camera.add_trauma(0.15)
		camera.shake()
		return true

	return false
