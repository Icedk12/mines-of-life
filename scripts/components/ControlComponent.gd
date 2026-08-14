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
	
## Allows custom behaviour when calling move and slide
func _move_and_slide_callback() -> void:
	character.move_and_slide()
