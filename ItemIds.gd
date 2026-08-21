extends Node

## Stores all items and their ids.
var item_ids : Dictionary[int, Item] = {
	0: Item.new("Stuffing", 0),
	1: Item.new("Leather Scrap", 1),
}

## Return the item correlating to the id passed in.
func get_item_by_id(id : int) -> Item:
	return item_ids[id]
