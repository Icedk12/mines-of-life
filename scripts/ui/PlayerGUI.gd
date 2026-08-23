class_name PlayerGUI extends Control

@export var inventory_ui : InventoryUI
@export var crafting_ui : CraftingUI
@export var inventory_component : InventoryComponent
@export var crafting_component : CraftingComponent

func _ready() -> void:
	inventory_ui.inventory_component = inventory_component
	inventory_ui.set_up()
	
	crafting_ui.crafting_component = crafting_component
	crafting_ui.inventory_component = inventory_component
	crafting_ui.set_up()
