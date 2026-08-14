class_name MovementComponent extends CharacterComponent

@export_group("Components")
@export var control_component : ControlComponent
@export var sprite_modifier_component : SpriteModifierComponent

@export_group("Movement")
@export var walk_speed : float = 100.0
@export var acceleration : float = 1.0
@export var deceleration : float = 1.0

var input_direction : float = 0.0
var walking : bool = false

func _physics_process(delta: float) -> void:
	if _is_character_null(): return
	
	input_direction = Input.get_axis("move_left", "move_right") # Store direction
	var x_velocity : float = input_direction * walk_speed # Calculate x velocity
	
	if x_velocity != 0 and character.is_on_floor():
		walking = true
		sprite_modifier_component._sprite_sin_offset(delta) # Move the character sprite up and down on a sine wave
	elif sprite_modifier_component.sprite.offset.y != 0:
		var return_speed = 10.0 # Pixels per second
		sprite_modifier_component.sprite.offset.y = move_toward(sprite_modifier_component.sprite.offset.y, 0.0, return_speed * delta)
	control_component.set_x(x_velocity)
	
