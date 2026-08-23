class_name CraftingRecipe extends Resource

@export var output_item_id : int
@export var output_amount : int = 1
@export var input_item_ids : Array[int] = []
@export var input_amounts : Array[int] = []   ## must follow same order of input item ids
