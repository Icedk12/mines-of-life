class_name InventoryComponent extends CharacterComponent

signal inventory_changed

enum ItemContainer { HOTBAR, INVENTORY }

@export var hotbar_size : int = 9
@export var inventory_size : int = 27

var hotbar : Array[ItemStack] = []
var inventory : Array[ItemStack] = []

func _ready() -> void:
	hotbar.resize(hotbar_size)
	for i in hotbar_size:
		hotbar[i] = ItemStack.new()

	inventory.resize(inventory_size)
	for i in inventory_size:
		inventory[i] = ItemStack.new()
	
	for item in ItemDatabase.item:
		add_item_by_id(item.item_id, 99)

func _get_array(container: ItemContainer) -> Array[ItemStack]:
	return hotbar if container == ItemContainer.HOTBAR else inventory

func _get_stack(container: ItemContainer, index: int) -> ItemStack:
	var arr := _get_array(container)
	if index < 0 or index >= arr.size():
		return null
	return arr[index]

## Total count of an item id across both hotbar and inventory
func get_total_count(id: int) -> int:
	var total := 0
	for s in hotbar:
		if s.item_id == id:
			total += s.amount
	for s in inventory:
		if s.item_id == id:
			total += s.amount
	return total

func has_item(id: int, amount: int = 1) -> bool:
	return get_total_count(id) >= amount

## Adds an item anywhere it fits
func add_item_by_id(id: int, amount: int = 1) -> int:
	if amount <= 0:
		return 0

	var item_data : ItemData = ItemDatabase.get_item_by_id(id)
	if item_data == null:
		print("Error: Item with ID " + str(id) + " not found!")
		return amount

	var remaining := amount
	remaining = _fill_existing_stacks(hotbar, id, item_data.stack_size, remaining)
	remaining = _fill_existing_stacks(inventory, id, item_data.stack_size, remaining)
	remaining = _fill_empty_slots(hotbar, id, item_data.stack_size, remaining)
	remaining = _fill_empty_slots(inventory, id, item_data.stack_size, remaining)

	if remaining < amount:
		inventory_changed.emit()
	if remaining > 0:
		print("Inventory full — could not add %d of item %d" % [remaining, id])

	return remaining

func _fill_existing_stacks(arr: Array[ItemStack], id: int, max_stack: int, remaining: int) -> int:
	for s in arr:
		if remaining <= 0:
			break
		if s.item_id == id and s.amount < max_stack:
			var add : int = min(max_stack - s.amount, remaining)
			s.amount += add
			remaining -= add
	return remaining

func _fill_empty_slots(arr: Array[ItemStack], id: int, max_stack: int, remaining: int) -> int:
	for s in arr:
		if remaining <= 0:
			break
		if s.is_empty():
			var add : int = min(max_stack, remaining)
			s.item_id = id
			s.amount = add
			remaining -= add
	return remaining

## Removes from wherever it can find it hotbar first, then inventory.
func remove_item_by_id(id: int, amount: int = 1) -> bool:
	if not has_item(id, amount):
		return false

	var remaining := amount
	remaining = _remove_from_array(hotbar, id, remaining)
	remaining = _remove_from_array(inventory, id, remaining)

	inventory_changed.emit()
	return remaining <= 0

func _remove_from_array(arr: Array[ItemStack], id: int, remaining: int) -> int:
	for s in arr:
		if remaining <= 0:
			break
		if s.item_id == id:
			var take : int = min(s.amount, remaining)
			s.amount -= take
			remaining -= take
			if s.amount <= 0:
				s.clear()
	return remaining

## Swaps the contents of two slots.
func move_stack(from_container: ItemContainer, from_index: int, to_container: ItemContainer, to_index: int) -> void:
	var from_stack = _get_stack(from_container, from_index)
	var to_stack = _get_stack(to_container, to_index)
	if from_stack == null or to_stack == null or from_stack.is_empty():
		return

	if to_stack.is_empty():
		to_stack.item_id = from_stack.item_id
		to_stack.amount = from_stack.amount
		from_stack.clear()
	elif to_stack.item_id == from_stack.item_id:
		var item_data := ItemDatabase.get_item_by_id(to_stack.item_id)
		var max_stack := item_data.stack_size if item_data else 999
		var moved : int = min(max_stack - to_stack.amount, from_stack.amount)
		to_stack.amount += moved
		from_stack.amount -= moved
		if from_stack.amount <= 0:
			from_stack.clear()
	else:
		var tmp_id = to_stack.item_id
		var tmp_amount = to_stack.amount
		to_stack.item_id = from_stack.item_id
		to_stack.amount = from_stack.amount
		from_stack.item_id = tmp_id
		from_stack.amount = tmp_amount

	inventory_changed.emit()

func has_space_for(id: int, amount: int) -> bool:
	var item_data := ItemDatabase.get_item_by_id(id)
	if item_data == null:
		return false

	var remaining := amount
	remaining = _simulate_fill(hotbar, id, item_data.stack_size, remaining)
	remaining = _simulate_fill(inventory, id, item_data.stack_size, remaining)
	return remaining <= 0

func _simulate_fill(arr: Array[ItemStack], id: int, max_stack: int, remaining: int) -> int:
	for s in arr:
		if remaining <= 0:
			return remaining
		if s.item_id == id:
			remaining -= max_stack - s.amount
		elif s.is_empty():
			remaining -= max_stack
	return remaining
