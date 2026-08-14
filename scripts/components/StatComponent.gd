class_name StatComponent extends CharacterComponent

@export_group("Ground Movement")
@export var default_walkspeed : float ## How fast the character walks when no modifiers are applied.
@export var default_acceleration : float = 1.0 ## A multiplier applied to the character's acceleration, 1.0 is the default value.
@export var default_deceleration : float = 7.0 ## A multiplier applied to the character's deceleration, 7.0 is the default value.

@export_group("Aerial Movement")
@export var default_jump_velocity : float ## The amount of upward velocity applied to the character when they jump when no modifiers are applied.
@export var max_air_jumps = 0 ## How many times the character can jump mid-air.
