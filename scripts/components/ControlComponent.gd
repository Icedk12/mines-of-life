class_name ControlComponent extends CharacterComponent

var knockback_timer : float = 0.0

func set_velocity(_velocity : Vector2) -> void:
	if character == null: return
	
	character.velocity += _velocity

func set_y(_y : float) -> void:
	if character == null or knockback_timer > 0.0: return
	character.velocity.y = _y
func set_x(_x : float) -> void:
	if character == null or knockback_timer > 0.0: return
	character.velocity.x = _x

func apply_knockback(direction: Vector2, force: float, duration: float = 0.2) -> void:
	if character == null: return
	character.velocity = direction * force
	knockback_timer = duration

func decelerate_x(delta : float) -> void:
	move_toward(character.velocity.x, 0, delta)
func decelerate_y(delta : float) -> void:
	move_toward(character.velocity.y, 0, delta)
	
func accelerate_x(delta : float, target_speed : float) -> void:
	move_toward(character.velocity.x, target_speed, delta)
func accelerate_y(delta : float, target_speed : float) -> void:
	move_toward(character.velocity.y, target_speed, delta)

func _physics_process(delta: float) -> void:
	if knockback_timer > 0.0:
		knockback_timer -= delta

## Allows custom behaviour when calling move and slide
func _move_and_slide_callback() -> void:
	character.move_and_slide()
