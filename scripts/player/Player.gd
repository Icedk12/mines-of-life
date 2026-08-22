class_name Player extends CharacterBody2D

@export var camera : ShakeableCamera2D
@export var control_component : ControlComponent
@export var sprite_modifier_component : SpriteModifierComponent
@export var level : Level
var state : State = State.MAIN_MENU

enum State {
	MAIN_MENU,
	PLAYING,
}
var was_in_air : bool = false

func start_player() -> void:
	state = State.PLAYING
	camera.enabled = true
	$SelectionBoxComponent/SelectionSprite.visible = true
	
	global_position = Vector2i(0,0)
	
	# Enable collision
	$Collision.disabled = false
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED

func _physics_process(delta: float) -> void:
	if not state == State.PLAYING: return
	was_in_air = !is_on_floor()
	
	# Execute movement
	control_component._move_and_slide_callback()
	
	# Check if we just landed on this frame right after move_and_slide()
	if was_in_air and is_on_floor():
		if sprite_modifier_component:
			sprite_modifier_component._squash()
