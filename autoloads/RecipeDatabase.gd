extends Node

@export var recipes : Array[CraftingRecipe] = []
var _by_id : Dictionary[int, CraftingRecipe] = {}

func _ready() -> void:
	for r in recipes:
		_by_id[r.output_item_id] = r

func get_block_by_id(id: int) -> CraftingRecipe:
	return _by_id.get(id)
