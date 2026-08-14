class_name MovementComponent extends CharacterComponent

@export_group("Components")
@export var control_component : ControlComponent
@export var sprite_modifier_component : SpriteModifierComponent

@export_group("Movement")
@export var walk_speed : float = 100.0
@export var acceleration : float = 1.0
@export var deceleration : float = 1.0

var input_direction : float = 0.0

func _physics_process(delta: float) -> void:
	if _is_character_null(): return
	
	input_direction = Input.get_axis("move_left", "move_right") # Store direction
	var x_velocity : float = input_direction * walk_speed # Calculate x velocity
	
	if x_velocity != 0 and character.is_on_floor():
		sprite_modifier_component._sprite_sin_offset(delta) # Move the character sprite up and down on a sine wave
	elif sprite_modifier_component.sprite.offset.y != 0:
		sprite_modifier_component.sprite.offset = Vector2.ZERO
	control_component.set_x(x_velocity)
	
