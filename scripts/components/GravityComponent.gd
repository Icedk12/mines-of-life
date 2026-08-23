class_name GravityComponent extends CharacterComponent

@export_group("Components")
@export var control_component : ControlComponent

@export_group("Gravity")
@export var gravity_multiplier : float = 1.0 : set = _set_gravity_multiplier ## Makes things fall faster
@export var terminal_velocity : float = 700.0 ## Maximum downward fall speed

func _physics_process(delta : float) -> void:
	if not character.is_on_floor():
		var current_y = character.velocity.y
		var gravity_step = character.get_gravity().y * delta * gravity_multiplier
		var new_y = minf(current_y + gravity_step, terminal_velocity)
		
		control_component.set_y(new_y)

## Returns the amount of gravity applied based on the current delta and gravity multiplier.
func _get_applied_gravity(delta : float) -> float:
	return character.get_gravity().y * delta * gravity_multiplier

## Sets the gravity multiplier
func _set_gravity_multiplier(new : float) -> void:
	gravity_multiplier = clampf(new, 0.01, 100.0)
