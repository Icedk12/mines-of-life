class_name InventoryUI extends Node

var inventory_component : InventoryComponent
@export var slot_scene : PackedScene = preload("res://scenes/ui/InventorySlot.tscn")
@export var grid : GridContainer
@export var selection_rect : TextureRect # Assign your visual selection overlay here!

var slots : Array[InventorySlot] = []
var selected_index : int = 0
var tween : Tween

func _input(event: InputEvent) -> void:
	if slots.is_empty():
		return
		
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			selected_index = posmod(selected_index - 1, slots.size())
			_move_selection_tween(selected_index)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			selected_index = posmod(selected_index + 1, slots.size())
			_move_selection_tween(selected_index)
			get_viewport().set_input_as_handled()

func set_up() -> void:
	for child in grid.get_children():
		if child is InventorySlot:
			child.queue_free()
	slots.clear()

	for i in inventory_component.inventory_size:
		var slot := slot_scene.instantiate() as InventorySlot
		grid.add_child(slot)
		slots.append(slot)

	if not inventory_component.inventory_changed.is_connected(_refresh):
		inventory_component.inventory_changed.connect(_refresh)
		
	_refresh()
	
	# Snap the selection overlay to the initial slot instantly
	if not slots.is_empty() and selection_rect:
		# Wait one frame for GridContainer layout to calculate correct positions
		await get_tree().process_frame
		selection_rect.global_position = slots[selected_index].global_position

func _refresh() -> void:
	var ids := inventory_component.inventory.keys()
	for i in slots.size():
		if i < ids.size():
			var id = ids[i]
			var item := ItemDatabase.get_item_by_id(id)
			slots[i].set_item(item, inventory_component.inventory[id])
		else:
			slots[i].clear()

func _move_selection_tween(target_index: int) -> void:
	if target_index < 0 or target_index >= slots.size() or not selection_rect:
		return

	var target_slot := slots[target_index]
	var target_pos := target_slot.global_position

	# Kill active tween to avoid conflicting animations during fast scrolling
	if tween and tween.is_running():
		tween.kill()

	tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Animate global_position to the targeted slot's global_position
	tween.tween_property(selection_rect, "global_position", target_pos, 0.05)
	
	# Optional juice: add a subtle scale punch during movement
	tween.parallel().tween_property(selection_rect, "scale", Vector2(1.1, 1.1), 0.075)
	tween.chain().tween_property(selection_rect, "scale", Vector2(1.0, 1.0), 0.075)
