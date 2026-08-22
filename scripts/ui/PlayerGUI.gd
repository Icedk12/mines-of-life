extends Control

@export var inventory_ui : InventoryUI
@export var inventory_component : InventoryComponent

func _ready() -> void:
	inventory_ui.inventory_component = inventory_component
	inventory_ui.set_up()
