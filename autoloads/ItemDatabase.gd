extends Node

@export var item : Array[ItemData] = []
var _by_id : Dictionary[int, ItemData] = {}
var _by_block_id : Dictionary[int, ItemData] = {}

func _ready() -> void:
	for b in item:
		_by_id[b.item_id] = b
	for i in item:
		if i.block_id != -1:
			_by_block_id[i.block_id] = i

func get_item_by_id(id: int) -> ItemData:
	return _by_id.get(id)

func get_item_by_block_id(block_id: int) -> ItemData:
	return _by_block_id.get(block_id)
