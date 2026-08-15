class_name JumpComponent extends CharacterComponent

@export_group("Components")
@export var control_component : ControlComponent
@export var sprite_modifier_component : SpriteModifierComponent

@export_group("Jump")
@export var jump_velocity : float = 100.0
@export var coyote_time : float = 0.15 ## Grace period in seconds

var coyote_timer : float = 0.0

func _physics_process(delta: float) -> void:
	_update_coyote_time(delta)
	
	if Input.is_action_just_pressed("jump") and _can_jump():
		_execute_jump()

func _update_coyote_time(delta: float) -> void:
	if character.is_on_floor():
		coyote_timer = coyote_time # Reset timer while grounded
	else:
		coyote_timer -= delta # Count down when in the air

## Returns true if grounded or coyote time
func _can_jump() -> bool:
	# Can jump if grounded or inside the coyote time window
	return coyote_timer > 0.0

## Applies upward velocity and resets coyote time
func _execute_jump() -> void:
	_on_jump()
	
	control_component.set_y(-jump_velocity) # Apply jump velocity
	if sprite_modifier_component:
		sprite_modifier_component._stretch() # Stretch sprite
	
	coyote_timer = 0.0 # Consume coyote time so player can't jump again in mid-air

## Callback for jump
func _on_jump() -> void:
	pass
