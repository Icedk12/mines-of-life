class_name JumpComponent extends CharacterComponent

@export_group("Components")
@export var control_component : ControlComponent
@export var sprite_modifier_component : SpriteModifierComponent

@export_group("Jump")
@export var jump_velocity : float = 100.0

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and character.is_on_floor() :
		control_component.set_y(-jump_velocity) # Apply jump velocity
		sprite_modifier_component._stretch() # Stretch sprite
		# TODO: Maybe make it lower gravity on first half of jump and higher in second half

func _on_jump() -> void:
	pass
