class_name CraftingUI extends Node

@export var inventory_component : InventoryComponent
@export var crafting_component : CraftingComponent
@export var slot_scene : PackedScene
@export var grid : GridContainer

var slots : Array[CraftingSlot] = []

func set_up() -> void:
	for recipe in RecipeDatabase.recipes:
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
