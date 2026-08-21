class_name Item extends Node

var item_name : String
var stack_size : int = 99
var id : int

func _init(_name : String, _id : int) -> void:
	item_name = _name
	id = _id

## Return the item's id.
func get_id() -> int:
	return id
