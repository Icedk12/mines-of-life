extends Node

@export var blocks : Array[BlockData] = []
var _by_id : Dictionary[int, BlockData] = {}

func _ready() -> void:
	for b in blocks:
		_by_id[b.block_id] = b

func get_block_by_id(id: int) -> BlockData:
	return _by_id.get(id)
