class_name InventorySlot extends PanelContainer

@export var icon_rect : TextureRect
@export var count_label : InventoryLabel

func set_item(item : ItemData, amount : int) -> void:
	if item == null: 
		print("Failed to add item to inventory")
		return
	visible = true
	icon_rect.texture = item.icon
	count_label.stack_size = str(item.stack_size)
	count_label.set_text_value(str(amount))

func clear() -> void:
	icon_rect.texture = null
	count_label.text = ""
