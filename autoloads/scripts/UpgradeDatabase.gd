extends Node

@export var upgrades : Array[Upgrade] = []
var _by_id : Dictionary[int, Upgrade] = {}

func _ready() -> void:
	for u in upgrades:
		_by_id[u.upgrade_id] = u

func get_upgrade_by_id(id: int) -> Upgrade:
	return _by_id.get(id)
