class_name EquipmentSlot extends InventorySlot

@export var category : EquipmentSlotMode.Mode

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not super._can_drop_data(at_position, data):
		return false
	
	var item_id : int = data.get("item_id", -1)
	var item := ItemDatabase.get_item_by_id(item_id)
	if item == null:
		return false

	return item.equipment_slot_mode == category
