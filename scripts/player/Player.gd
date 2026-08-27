class_name Player extends CharacterBody2D

@onready var light : PulsingLight = $SelfLight
@onready var sprite : Sprite2D = $Sprite
@onready var camera : ShakeableCamera2D = $Camera

@export var health_component : HealthComponent
@export var mine_component : MineComponent
@export var control_component : ControlComponent
@export var sprite_modifier_component : SpriteModifierComponent
@export var level : Level
var state : State = State.MAIN_MENU

var knockback: Vector2 = Vector2.ZERO

enum State {
	MAIN_MENU,
	PLAYING,
}
var was_in_air : bool = false

func start_player() -> void:
	state = State.PLAYING
	camera.enabled = true
	$SelectionBoxComponent/SelectionSprite.visible = true
	$UILayer.visible = true
	
	global_position = Vector2i(0,0)
	
	# Enable collision
	$Collision.disabled = false
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED

func _physics_process(delta: float) -> void:
	if not state == State.PLAYING: return
	was_in_air = !is_on_floor()
	
	control_component._move_and_slide_callback()
	
	if was_in_air and is_on_floor():
		if sprite_modifier_component:
			sprite_modifier_component._squash()

	sprite_modifier_component._sprite_rotation(delta, velocity.length() > 0.1)

func apply_knockback(direction: Vector2, force: float) -> void:
	if control_component:
		control_component.apply_knockback(direction, force)
