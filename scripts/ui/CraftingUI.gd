class_name CraftingUI extends Node

@export var inventory_component : InventoryComponent
@export var crafting_component : CraftingComponent
@export var slot_scene : PackedScene
@export var grid : GridContainer

var slots : Array[CraftingSlot] = []

func set_up() -> void:
	var sorted_recipes := RecipeDatabase.recipes.duplicate()
	sorted_recipes.sort_custom(_sort_by_item_name)

	for recipe in sorted_recipes:
		var slot := slot_scene.instantiate() as CraftingSlot
		grid.add_child(slot)
		slot.bind(recipe, crafting_component, inventory_component)
		slots.append(slot)
		slot.hover_label = $"../HoverLabel"

	if inventory_component:
		inventory_component.inventory_changed.connect(_refresh_all)
		
	if crafting_component:
		crafting_component.crafting_updated.connect(_refresh_all)

func _refresh_all() -> void:
	for slot in slots:
		slot.refresh()

func _sort_by_item_name(a: CraftingRecipe, b: CraftingRecipe) -> bool:
	var item_a := ItemDatabase.get_item_by_id(a.output_item_id)
	var item_b := ItemDatabase.get_item_by_id(b.output_item_id)

	var name_a := item_a.item_name if item_a else ""
	var name_b := item_b.item_name if item_b else ""

	return name_a.nocasecmp_to(name_b) < 0
