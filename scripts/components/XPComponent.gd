class_name XPComponent extends CharacterComponent

signal xp_changed(current : float, max : float)
signal level_up

@export var scale_factor : float = 1.67

var level : int = 1
var xp : float = 0.0
var max_xp : float = 100.0

func add_xp(xp_to_add : float) -> void:
	xp += xp_to_add
	
	while xp >= max_xp:
		xp -= max_xp
		level += 1
		max_xp = level * scale_factor
		level_up.emit()
		
	xp_changed.emit(xp, max_xp)
