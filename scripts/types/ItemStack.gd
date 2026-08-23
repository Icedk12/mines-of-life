class_name ItemStack

var item_id : int = -1
var amount : int = 0

func _init(_item_id : int = -1, _amount : int = 0) -> void:
	item_id = _item_id
	amount = _amount

func is_empty() -> bool:
	return item_id == -1 or amount <= 0

func clear() -> void:
	item_id = -1
	amount = 0
