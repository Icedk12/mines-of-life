class_name MovementComponent extends CharacterComponent

@export_group("Components")
@export var stat_manager : StatManager
@export var control_component : ControlComponent
@export var sprite_modifier_component : SpriteModifierComponent
@export var input_component : InputComponent

@export_group("Movement")
@export var walk_speed : float = 100.0
@export var acceleration : float = 800.0 # Increased: unit is pixels/sec^2
@export var deceleration : float = 1000.0 # Increased: unit is pixels/sec^2

var input_direction : float = 0.0
var walking : bool = false

func _physics_process(delta: float) -> void:
	if _is_character_null(): 
		return
	
	input_direction = input_component._get_input_direction()
	var target_velocity_x : float = input_direction * (walk_speed + stat_manager.final_stats.speed_offset) * stat_manager.final_stats.speed_modifier
	
	# Fetch current X velocity from your character/control component
	var current_velocity_x : float = character.velocity.x 
	
	# Determine whether to use acceleration or deceleration rate
	var accel_rate : float = acceleration if input_direction != 0 else deceleration
	
	# Smoothly transition current velocity toward target velocity
	var new_velocity_x : float = move_toward(current_velocity_x, target_velocity_x, accel_rate * delta)
	
	control_component.set_x(new_velocity_x)
	
	# Visual/Sprite logic
	if new_velocity_x != 0 and character.is_on_floor():
		on_walk(delta)
	elif sprite_modifier_component.sprite.offset.y != 0:
		reset_sprite_offset(delta)

func on_walk(delta : float) -> void:
	sprite_modifier_component._sprite_sin_offset(delta, true)

func reset_sprite_offset(delta : float) -> void:
	# Smoothly return the offset back to zero over time
	sprite_modifier_component.sprite.offset.y = move_toward(
		sprite_modifier_component.sprite.offset.y, 
		0.0, 
		10.0 * delta
	)
