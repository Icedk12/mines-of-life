class_name GravityComponent extends CharacterComponent

@export_group("Components")
@export var control_component : ControlComponent

@export_group("Gravity")
@export var gravity_multiplier : float = 1.0 : set = _set_gravity_multiplier ## Makes things fall faster


func _physics_process(delta : float) -> void:
	if not character.is_on_floor():
		control_component.set_velocity((character.get_gravity() * delta) * gravity_multiplier)

## Returns the amount of gravity applied based on the current delta and gravity multiplier.
func _get_applied_gravity(delta : float) -> float:
	return Vector2((character.get_gravity() * delta) * gravity_multiplier).y

## Sets the gravity multiplier
func _set_gravity_multiplier(new : float) -> float:
	return clampf(new, 0.01, 100.0)
