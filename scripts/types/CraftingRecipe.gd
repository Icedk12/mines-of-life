class_name CraftingRecipe extends Resource

@export var output_item_id : int
@export var output_amount : int = 1
@export var input_item_ids : Array[int] = []
@export var input_amounts : Array[int] = []    ## must follow same order of input item ids

func get_recipe_str() -> String:
	var ret : String = ""
	for i in range(input_item_ids.size()):
		var item_id : int = input_item_ids[i]
		var amount : int = input_amounts[i]
		var item : ItemData = ItemDatabase.get_item_by_id(item_id)
		
		ret += item.item_name + "[" + str(amount) + "],"
	return ret
