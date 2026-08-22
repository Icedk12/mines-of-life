class_name InventoryUI extends Node

var inventory_component : InventoryComponent
@export var slot_scene : PackedScene = preload("res://scenes/ui/InventorySlot.tscn")
@export var grid : GridContainer

var slots : Array[InventorySlot] = []

func set_up() -> void:
	for i in inventory_component.inventory_size:
		var slot := slot_scene.instantiate() as InventorySlot
		grid.add_child(slot)
		slots.append(slot)

	inventory_component.inventory_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	var ids := inventory_component.inventory.keys()
	for i in slots.size():
		if i < ids.size():
			var id = ids[i]
			var item := ItemDatabase.get_item_by_id(id)
			slots[i].set_item(item, inventory_component.inventory[id])
		else:
			slots[i].clear()
