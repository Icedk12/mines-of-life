class_name InventorySlot extends PanelContainer

signal slot_pressed(block_id: int)

@export var icon_rect : TextureRect
@export var count_label : InventoryLabel

var block_id : int = -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			if block_id != -1:
				slot_pressed.emit(block_id)

func set_item(id: int, item : ItemData, amount : int) -> void:
	if item == null:
		clear()
		return

	block_id = id
	visible = true
	icon_rect.texture = item.icon
	count_label.stack_size = str(item.stack_size)
	count_label.set_text_value(str(amount))

func clear() -> void:
	block_id = -1
	icon_rect.texture = null
	count_label.stack_size = ""
	count_label.set_text_value("")
