extends Node

@export var item : Array[ItemData] = []
var _by_id : Dictionary[int, ItemData] = {}

func _ready() -> void:
	for b in item:
		_by_id[b.item_id] = b

func get_item_by_id(id: int) -> ItemData:
	return _by_id.get(id)
