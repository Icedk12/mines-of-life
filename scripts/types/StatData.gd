class_name StatData extends Resource

@export var health_modifier : float = 1.0
@export var health_offset : float = 0.0

@export var speed_modifier : float = 1.0
@export var speed_offset : float = 0.0

@export var jump_modifier : float = 1.0
@export var jump_offset : float = 0.0

@export var damage_modifier : float = 1.0
@export var damage_offset : float = 0.0

@export var mine_damage_modifier : float = 1.0
@export var mine_damage_offset : float = 0.0

func _init() -> void:
	health_modifier = 1.0
	health_offset = 0.0

	speed_modifier = 1.0
	speed_offset = 0.0

	jump_modifier = 1.0
	jump_offset = 0.0

	damage_modifier = 1.0
	damage_offset = 0.0

	mine_damage_modifier  = 1.0
	mine_damage_offset  = 0.0
