class_name XPComponent extends CharacterComponent

signal xp_changed(current : float, max : float)
signal level_up(new_level : int)

@export var base_max_xp : float = 100.0 ## XP required to go from level 1 to level 2
@export var scale_factor : float = 1.1 ## Each level's requirement is multiplied by this

var level : int = 1
var xp : float = 0.0
var max_xp : float = base_max_xp

func add_xp(xp_to_add : float) -> void:
	xp += xp_to_add
	
	while xp >= max_xp:
		xp -= max_xp
		level += 1
		max_xp = base_max_xp * pow(scale_factor, level - 1)
		level_up.emit(level)
		
	xp_changed.emit(xp, max_xp)
