class_name StatContainer extends Resource

@export_group("Ground Movement")
@export var default_walkspeed : float ## How fast the player walks when no modifiers are applied.
@export var default_acceleration_factor : float = 1.0 ## A multiplier applied to the player's acceleration, 1.0 is the default value.
@export var default_deceleration_factor : float = 1.0 ## A multiplier applied to the player's deceleration, 1.0 is the default value.

@export_group("Aerial Movement")
@export var default_jump_velocity : float ## The amount of upward velocity applied to the player when they jump when no modifiers are applied.
@export var max_air_jumps = 0 ## How many times the player can jump mid-air.
