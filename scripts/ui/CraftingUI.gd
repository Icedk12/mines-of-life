class_name CraftingUI extends Node

@export var inventory_component : InventoryComponent
@export var crafting_component : CraftingComponent
@export var slot_scene : PackedScene
@export var grid : GridContainer

var slots : Array[CraftingSlot] = []

func set_up() -> void:
	print("CraftingUI.set_up() called")
	print("RecipeDatabase.recipes size: ", RecipeDatabase.recipes.size())
	print("crafting_component: ", crafting_component)
	print("inventory_component: ", inventory_component)
	print("grid: ", grid)

	for recipe in RecipeDatabase.recipes:
		var slot := slot_scene.instantiate() as CraftingSlot
		grid.add_child(slot)
		slot.bind(recipe, crafting_component, inventory_component)
		slots.append(slot)
		slot.hover_label = $"../HoverLabel"

	inventory_component.inventory_changed.connect(_refresh_all)
	

func _refresh_all() -> void:
	for slot in slots:
		slot.refresh()
