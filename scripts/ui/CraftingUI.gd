class_name CraftingUI extends Node

@export var inventory_component : InventoryComponent
@export var crafting_component : CraftingComponent
@export var slot_scene : PackedScene = preload("res://scenes/ui/CraftingSlot.tscn")
@export var grid : GridContainer

var slots : Array[CraftingSlot] = []

func set_up() -> void:
	for recipe in crafting_component.recipes:
		var slot := slot_scene.instantiate() as CraftingSlot
		grid.add_child(slot)
		slot.bind(recipe, crafting_component, inventory_component)
		slots.append(slot)

	inventory_component.inventory_changed.connect(_refresh_all)

func _refresh_all() -> void:
	for slot in slots:
		slot.refresh()
