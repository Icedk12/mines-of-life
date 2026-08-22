class_name InventoryUI extends Node

signal selection_changed(block_id: int)

@export var inventory_component : InventoryComponent
@export var slot_scene : PackedScene = preload("res://scenes/ui/InventorySlot.tscn")
@export var grid : GridContainer
@export var selection_rect : Control
@export var tween_duration : float = 0.1

var slots : Array[InventorySlot] = []
var selected_index : int = 0
var selected_block_id : int = -1
var active_tween : Tween

func set_up() -> void:
	for i in inventory_component.inventory_size:
		var slot := slot_scene.instantiate() as InventorySlot
		grid.add_child(slot)
		slot.slot_pressed.connect(_on_slot_pressed)
		slots.append(slot)

	inventory_component.inventory_changed.connect(_refresh)
	
	await get_tree().process_frame
	_refresh()
	_move_selection_rect(true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_change_selection(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_change_selection(1)

func _change_selection(direction: int) -> void:
	var ids := inventory_component.inventory.keys()
	if ids.is_empty():
		return

	selected_index = wrapi(selected_index + direction, 0, ids.size())
	_refresh()

func _on_slot_pressed(block_id: int) -> void:
	var ids := inventory_component.inventory.keys()
	var idx := ids.find(block_id)
	if idx != -1:
		selected_index = idx
		_refresh()

func _refresh() -> void:
	var ids := inventory_component.inventory.keys()

	if ids.is_empty():
		selected_index = 0
		selected_block_id = -1
	else:
		selected_index = clampi(selected_index, 0, ids.size() - 1)
		selected_block_id = ids[selected_index]

	selection_changed.emit(selected_block_id)

	for i in slots.size():
		if i < ids.size():
			var id = ids[i]
			var item := ItemDatabase.get_item_by_id(id)
			slots[i].set_item(id, item, inventory_component.inventory[id])
		else:
			slots[i].clear()

	if selection_rect:
		selection_rect.visible = not ids.is_empty()

	_move_selection_rect()

func _move_selection_rect(snap: bool = false) -> void:
	if not selection_rect or slots.is_empty() or selected_block_id == -1:
		return

	var target_slot := slots[selected_index]
	var target_pos : Vector2 = target_slot.global_position

	if active_tween and active_tween.is_running():
		active_tween.kill()

	if snap:
		selection_rect.global_position = target_pos
		return

	active_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(selection_rect, "global_position", target_pos, tween_duration)
