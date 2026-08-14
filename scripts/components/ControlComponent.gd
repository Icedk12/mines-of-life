class_name ControlComponent extends CharacterComponent

func set_velocity(_velocity : Vector2) -> void:
	if character == null: return
	
	character.velocity += _velocity

func set_y(_y : float) -> void:
	if character == null: return
	character.velocity.y = _y
func set_x(_x : float) -> void:
	if character == null: return
	character.velocity.x = _x
	
func decelerate_x(delta : float) -> void:
	move_toward(character.velocity.x, 0, delta)
func decelerate_y(delta : float) -> void:
	move_toward(character.velocity.y, 0, delta)
	
func accelerate_x(delta : float, target_speed : float) -> void:
	move_toward(character.velocity.x, target_speed, delta)
func accelerate_y(delta : float, target_speed : float) -> void:
	move_toward(character.velocity.y, target_speed, delta)

## Allows custom behaviour when calling move and slide
func _move_and_slide_callback() -> void:
	character.move_and_slide()
