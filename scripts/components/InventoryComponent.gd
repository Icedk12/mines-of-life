class_name InventoryComponent extends CharacterComponent

@export var inventory_size: int = 10

var inventory: Dictionary[int, int] = {}

func _ready() -> void:
	add_item_by_id(0, 2)

## Checks if the inventory has enough of a specific item ID
func has_item(id: int, amount: int = 1) -> bool:
	return inventory.get(id, 0) >= amount

## Adds an item to the inventory by ID, respecting stack size
func add_item_by_id(id: int, amount: int = 1) -> void:
	if amount <= 0:
		return

	var item_data : Item = ItemIds.get_item_by_id(id)
	if item_data == null:
		print("Error: Item with ID " + str(id) + " not found!")
		return

	var current_amount = inventory.get(id, 0)
	var max_stack = item_data.stack_size

	# APPLY STACK SIZE LIMIT
	if current_amount + amount > max_stack:
		print("Cannot add all items. Stack limit reached for " + item_data.name + "!")
		amount = max_stack - current_amount
		if amount <= 0:
			return

	# CHECK IF INVENTORY FULL
	if not inventory.has(id) and inventory.size() >= inventory_size:
		print("Cannot add item: Inventory full (no empty slots)!")
		return

	# UPDATE INVENTORY COUNT
	inventory[id] = current_amount + amount
	print("Gained " + str(amount) + " of " + item_data.item_name + " (Total: " + str(inventory[id]) + "/" + str(max_stack) + ")")


## Adds an item using an Item object
func add_item_by_item(item: Item, amount: int = 1) -> void:
	if item == null:
		return
	add_item_by_id(item.get_id(), amount)


## Safely removes an item from the inventory
func remove_item_by_id(id: int, amount: int = 1) -> bool:
	if not inventory.has(id) or inventory[id] < amount:
		print("Not enough items to remove!")
		return false

	inventory[id] -= amount
	
	# Clean up empty slots
	if inventory[id] <= 0:
		inventory.erase(id)

	return true
