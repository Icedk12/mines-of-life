class_name CraftingComponent extends CharacterComponent

@export var inventory_component : InventoryComponent

func can_craft(recipe: CraftingRecipe) -> bool:
	for i in recipe.input_item_ids.size():
		if not inventory_component.has_item(recipe.input_item_ids[i], recipe.input_amounts[i]):
			return false
	return inventory_component.has_space_for(recipe.output_item_id, recipe.output_amount)

func craft(recipe: CraftingRecipe) -> bool:
	if not can_craft(recipe):
		return false
	for i in recipe.input_item_ids.size():
		inventory_component.remove_item_by_id(recipe.input_item_ids[i], recipe.input_amounts[i])
	return true
