class_name InventorySlot extends PanelContainer

signal slot_pressed(container: InventoryComponent.ItemContainer, index: int)
signal item_dropped(data: Dictionary, target_container: InventoryComponent.ItemContainer, target_index: int)

@export var icon_rect : TextureRect
@export var count_label : InventoryLabel
@export var hover_label : Label

var container : InventoryComponent.ItemContainer
var index : int = -1
var stack : ItemStack
var is_hovered : bool

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	is_hovered = true
	_update_hover_label()

func _on_mouse_exited() -> void:
	is_hovered = false
	if hover_label:
		hover_label.visible = false

func bind(_container: InventoryComponent.ItemContainer, _index: int) -> void:
	container = _container
	index = _index

func set_stack(_stack : ItemStack) -> void:
	stack = _stack
	if stack == null or stack.is_empty():
		clear()
		return

	var item := ItemDatabase.get_item_by_id(stack.item_id)
	if item == null:
		clear()
		return

	icon_rect.texture = item.icon
	count_label.stack_size = str(item.stack_size)
	count_label.set_text_value(str(stack.amount) if stack.amount > 1 else "")

func clear() -> void:
	icon_rect.texture = null
	count_label.stack_size = ""
	count_label.set_text_value("")

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and is_hovered:
		if hover_label and hover_label.visible:
			hover_label.global_position = get_global_mouse_position()

	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			if stack and not stack.is_empty():
				slot_pressed.emit(container, index)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_start_split_drag()

func _update_hover_label() -> void:
	if stack != null and not stack.is_empty():
		var item := ItemDatabase.get_item_by_id(stack.item_id)
		if item and hover_label:
			hover_label.text = item.item_name
			hover_label.global_position = get_global_mouse_position()
			hover_label.visible = true
			return
	
	if hover_label:
		hover_label.visible = false

func _start_split_drag() -> void:
	if not stack or stack.is_empty() or stack.amount < 2:
		return

	var half := stack.amount / 2
	var data := {
		"source_container": container,
		"source_index": index,
		"item_id": stack.item_id,
		"amount": half,
		"is_split": true,
	}
	force_drag(data, _make_preview(stack.item_id, half))

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not stack or stack.is_empty():
		return null

	var data := {
		"source_container": container,
		"source_index": index,
		"item_id": stack.item_id,
		"amount": stack.amount,
		"is_split": false,
	}
	set_drag_preview(_make_preview(stack.item_id, stack.amount))
	return data

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and (data.has("source_container") or data.get("is_craft", false))

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	item_dropped.emit(data, container, index)

func _make_preview(item_id: int, amount: int) -> Control:
	var item := ItemDatabase.get_item_by_id(item_id)
	var preview := TextureRect.new()
	if item:
		preview.texture = item.icon
	preview.custom_minimum_size = Vector2(48, 48)
	preview.modulate.a = 0.8
	return preview

func _display_info() -> void:
	if is_hovered and stack != null and not stack.is_empty():
		var item := ItemDatabase.get_item_by_id(stack.item_id)
		if item:
			hover_label.text = item.item_name
			hover_label.global_position = get_global_mouse_position()
			hover_label.visible = true
			return

	hover_label.visible = false
