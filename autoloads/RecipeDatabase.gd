extends Node

@export var recipes : Array[CraftingRecipe] = []
var _by_id : Dictionary[int, CraftingRecipe] = {}

func _ready() -> void:
	for r in recipes:
		if _by_id.has(r.output_item_id):
			push_warning("Duplicate recipe output_item_id %d — earlier recipe for this item will be shadowed by get_recipe_by_id()" % r.output_item_id)
		_by_id[r.output_item_id] = r

func get_recipe_by_id(id: int) -> CraftingRecipe:
	return _by_id.get(id)
