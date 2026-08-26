class_name InventoryUI extends Node

signal selection_changed(item_id: int)

@export var inventory_component : InventoryComponent
@export var slot_scene : PackedScene = preload("res://scenes/ui/InventorySlot.tscn")
@export var hotbar_grid : GridContainer
@export var inventory_grid : GridContainer
@export var selection_rect : Control
@export var tween_duration : float = 0.1
@export var inventory_panel : Control ## the full backpack view, toggled separately from the always-visible hotbar
@export var inventory_trans : Tween.TransitionType

@export var equipment_slots : Array[EquipmentSlot] = []

var hotbar_slots : Array[InventorySlot] = []
var inventory_slots : Array[InventorySlot] = []
var selected_hotbar_index : int = 0
var active_tween : Tween
var inventory_tween : Tween
var setting_tween : Tween

func set_up() -> void:
	for i in inventory_component.hotbar.size():
		hotbar_slots.append(_make_slot(InventoryComponent.ItemContainer.HOTBAR, i, hotbar_grid))

	for i in inventory_component.inventory.size():
		inventory_slots.append(_make_slot(InventoryComponent.ItemContainer.INVENTORY, i, inventory_grid))

	for slot in equipment_slots:
		slot.bind(InventoryComponent.ItemContainer.EQUIPMENT, slot.category) # index == the slot's own category value
		slot.hover_label = $"../HoverLabel"
		slot.slot_pressed.connect(_on_slot_pressed)
		slot.item_dropped.connect(_on_item_dropped)

	inventory_component.inventory_changed.connect(_refresh)

	await get_tree().process_frame
	_refresh()
	_move_selection_rect(true)

func _make_slot(container: InventoryComponent.ItemContainer, index: int, grid: GridContainer) -> InventorySlot:
	var slot := slot_scene.instantiate() as InventorySlot
	slot.bind(container, index)
	slot.hover_label = $"../HoverLabel"
	grid.add_child(slot)
	slot.slot_pressed.connect(_on_slot_pressed)
	slot.item_dropped.connect(_on_item_dropped)
	return slot

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_change_selection(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_change_selection(1)
	elif event.is_action_pressed("settings") and $"../Settings":
		if setting_tween and setting_tween.is_running():
			setting_tween.kill()
		setting_tween = create_tween().set_trans(inventory_trans)
		
		if not $"../Settings".visible:
			$"../Settings".visible = true
			setting_tween.tween_property($"../Settings", "position", Vector2(499.0, 237.0), 0.5)
		else:
			setting_tween.tween_property($"../Settings", "position", Vector2(499.0, 1122.0), 0.5)
			setting_tween.tween_callback(func(): $"../Settings".visible = false)
		
	elif event.is_action_pressed("toggle_inventory") and inventory_panel:
		if inventory_tween and inventory_tween.is_running():
			inventory_tween.kill()
		inventory_tween = create_tween().set_trans(inventory_trans)

		if not inventory_panel.visible:
			inventory_panel.visible = true
			inventory_tween.tween_property(inventory_panel, "position", Vector2(460.0, 405.0), 0.5)

		else:
			inventory_tween.tween_property(inventory_panel, "position", Vector2(460.0, 1122.0), 0.5)
			inventory_tween.tween_callback(func(): inventory_panel.visible = false)

func _change_selection(direction: int) -> void:
	if inventory_component.hotbar.is_empty():
		return
	selected_hotbar_index = wrapi(selected_hotbar_index + direction, 0, inventory_component.hotbar.size())
	_on_selection_changed()

func _on_slot_pressed(container: InventoryComponent.ItemContainer, index: int) -> void:
	if container == InventoryComponent.ItemContainer.HOTBAR:
		selected_hotbar_index = index
		_on_selection_changed()

func _on_selection_changed() -> void:
	selection_changed.emit(get_selected_item_id())
	_move_selection_rect()

func _on_item_dropped(data: Dictionary, target_container: InventoryComponent.ItemContainer, target_index: int) -> void:
	if data.get("is_craft", false):
		_handle_craft_drop(data, target_container, target_index)
		return

	var source_container : InventoryComponent.ItemContainer = data.source_container
	var source_index : int = data.source_index

	if source_container == target_container and source_index == target_index:
		return

	if data.get("is_split", false):
		_handle_split_drop(data, target_container, target_index)
	else:
		inventory_component.move_stack(source_container, source_index, target_container, target_index)

func _handle_split_drop(data: Dictionary, target_container: InventoryComponent.ItemContainer, target_index: int) -> void:
	var target_stack := inventory_component._get_stack(target_container, target_index)
	if target_stack == null:
		return
	if not target_stack.is_empty() and target_stack.item_id != data.item_id:
		return # can't split onto a different item

	var source_stack := inventory_component._get_stack(data.source_container, data.source_index)
	if source_stack == null or source_stack.amount < data.amount:
		return

	var item := ItemDatabase.get_item_by_id(data.item_id)
	var max_stack := item.stack_size if item else 999
	var move_amount : int = data.amount

	if target_stack.is_empty():
		target_stack.item_id = data.item_id
		target_stack.amount = move_amount
	else:
		move_amount = min(max_stack - target_stack.amount, move_amount)
		target_stack.amount += move_amount

	source_stack.amount -= move_amount
	if source_stack.amount <= 0:
		source_stack.clear()

	inventory_component.inventory_changed.emit()
	inventory_component.recalculate_equipment_stats()

func _refresh() -> void:
	for i in hotbar_slots.size():
		hotbar_slots[i].set_stack(inventory_component._get_stack(InventoryComponent.ItemContainer.HOTBAR, i))
	for i in inventory_slots.size():
		inventory_slots[i].set_stack(inventory_component._get_stack(InventoryComponent.ItemContainer.INVENTORY, i))
	for slot in equipment_slots:
		slot.set_stack(inventory_component._get_stack(InventoryComponent.ItemContainer.EQUIPMENT, slot.category))
	_on_selection_changed()
	
func _move_selection_rect(snap: bool = false) -> void:
	if not selection_rect or hotbar_slots.is_empty():
		return

	var target_slot := hotbar_slots[selected_hotbar_index]
	var target_pos : Vector2 = target_slot.global_position + (target_slot.size - selection_rect.size) * 0

	if active_tween and active_tween.is_running():
		active_tween.kill()

	if snap:
		selection_rect.global_position = target_pos
		return

	active_tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(selection_rect, "global_position", target_pos, tween_duration)

## The currently selected hotbar item id, or -1
func get_selected_item_id() -> int:
	var stack := inventory_component._get_stack(InventoryComponent.ItemContainer.HOTBAR, selected_hotbar_index)
	return stack.item_id if stack and not stack.is_empty() else -1

func _handle_craft_drop(data: Dictionary, target_container: InventoryComponent.ItemContainer, target_index: int) -> void:
	var target_stack := inventory_component._get_stack(target_container, target_index)
	var item := ItemDatabase.get_item_by_id(data.item_id)
	var max_stack := item.stack_size if item else 999

	if target_stack and (target_stack.is_empty() or target_stack.item_id == data.item_id) and target_stack.amount < max_stack:
		var placed : int = min(max_stack - target_stack.amount, data.amount)
		target_stack.item_id = data.item_id
		target_stack.amount += placed
		var leftover : int = data.amount - placed
		if leftover > 0:
			inventory_component.add_item_by_id(data.item_id, leftover)
		inventory_component.inventory_changed.emit()
		inventory_component.recalculate_equipment_stats()
	else:
		inventory_component.add_item_by_id(data.item_id, data.amount)
