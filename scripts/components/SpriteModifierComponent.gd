class_name SpriteModifierComponent
extends CharacterComponent

@export_group("Objects")
@export var sprite : Sprite2D ## Character's sprite you want to modify
@export var audio_source : AudioSourceComponent ## Sibling component that plays footstep sounds

@export_group("Tweens")
@export var squash_tween : TweenInfo
@export var stretch_tween : TweenInfo
@export var return_tween : TweenInfo ## How long it takes to return to normal value after tween

@export_group("Mining Tweens")
@export var mining_tween : TweenInfo
@export var mining_angle_degrees : float = 40.0

@export_group("Sin")
@export var frequency : float = 25.0
@export var amplitude : float = 1.0
@export var rot_amplitude : float = 5.0
@export var rot_frequency : float = 25.0

var active_tween : Tween ## Track active tween to prevent spamming
var _sin_time : float = 0.0
var _played_step_this_cycle : bool = false

## Face the sprite in the direction given (either left or right)
func _face_dir(direction : float):
	if not sprite: return
	sprite.flip_h = (direction < 0) # If direction is greater than 0 flip

## Rotate sprite while moving for animation
func _sprite_rotation(delta : float, is_moving : bool) -> void:
	if not sprite: return

	if is_moving:
		_sin_time += delta
		sprite.rotation_degrees = sin(_sin_time * rot_frequency) * rot_amplitude
	else:
		sprite.rotation_degrees = lerp(sprite.rotation_degrees, 0.0, 0.1)

## Squash the sprite
func _squash() -> void:
	if not sprite or not squash_tween or not return_tween: return
	_verify_tween()
	
	# Tween the sprite's scale
	active_tween.tween_property(sprite, "scale", squash_tween.scale, squash_tween.duration)\
		.set_trans(squash_tween.transition_type).set_ease(squash_tween.easing_style)
	
	_return_from_tween()

## Stretch the sprite
func _stretch() -> void:
	if not sprite or not stretch_tween or not return_tween: return
	_verify_tween()
	
	active_tween.tween_property(sprite, "scale", stretch_tween.scale, stretch_tween.duration)\
		.set_trans(stretch_tween.transition_type).set_ease(stretch_tween.easing_style)
	
	_return_from_tween()

## Offset the Y value of the sprite using sin() and delta, and trigger footsteps at the bob's low point
func _sprite_sin_offset(delta : float, is_moving : bool) -> void:
	if not sprite: return

	if is_moving:
		_sin_time += delta
		var wave := sin(_sin_time * frequency)
		sprite.offset.y = (-wave * amplitude) - 1

		if wave < -0.9:
			if not _played_step_this_cycle:
				if audio_source:
					audio_source.play_footstep()
				_played_step_this_cycle = true
		else:
			_played_step_this_cycle = false
	else:
		sprite.offset.y = lerp(sprite.offset.y, -1.0, delta * 10.0)
		_played_step_this_cycle = false

# ============= HELPER FUNCTIONS ============= #
## Tweens the sprite to Vector2.ONE, aka default scale
func _return_from_tween() -> void:
	active_tween.tween_property(sprite, "scale", return_tween.scale, return_tween.duration)\
		.set_trans(return_tween.transition_type).set_ease(return_tween.easing_style)

## Helper function to kill the tween if its already running
func _verify_tween() -> void:
	# ^^^^^^ Hey it's me its verity 😃
	# ayo nah verity gtfo my code
	#
	# for i in range(64):
	# 	print("Larp")
	
	if active_tween and active_tween.is_running():
		active_tween.kill()
	
	active_tween = create_tween()

func _mining_tween(direction : Vector2 = Vector2.RIGHT) -> void:
	if not sprite or not mining_tween or not return_tween: return
	_verify_tween()
	
	var dir_x : float = sign(direction.x) if direction.x != 0 else 1.0
	var target_rotation : float = deg_to_rad(mining_angle_degrees * dir_x)
	
	active_tween.set_parallel(true)
	active_tween.tween_property(sprite, "rotation", target_rotation, mining_tween.duration)\
		.set_trans(mining_tween.transition_type).set_ease(mining_tween.easing_style)
	active_tween.tween_property(sprite, "scale", mining_tween.scale, mining_tween.duration)\
		.set_trans(mining_tween.transition_type).set_ease(mining_tween.easing_style)
	
	active_tween.chain().set_parallel(true)
	active_tween.tween_property(sprite, "scale", return_tween.scale, return_tween.duration)\
		.set_trans(return_tween.transition_type).set_ease(return_tween.easing_style)
	active_tween.tween_property(sprite, "rotation", 0.0, return_tween.duration)\
		.set_trans(return_tween.transition_type).set_ease(return_tween.easing_style)