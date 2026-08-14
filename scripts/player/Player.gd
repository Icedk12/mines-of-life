class_name Player extends CharacterBody2D

@export var control_component : ControlComponent
@export var sprite_modifier_component : SpriteModifierComponent

var was_in_air : bool = false

func _physics_process(delta: float) -> void:
	was_in_air = !is_on_floor()
	
	# Execute movement
	control_component._move_and_slide_callback()
	
	# Check if we just landed on this frame right after move_and_slide()
	if was_in_air and is_on_floor():
		if sprite_modifier_component:
			sprite_modifier_component._squash()
