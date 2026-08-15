class_name SpriteModifierComponent extends CharacterComponent

@export_group("Objects")
@export var sprite : Sprite2D ## Character's sprite you want to modify

@export_group("Tweens")
@export var squash_tween : TweenInfo
@export var stretch_tween : TweenInfo
@export var return_tween : TweenInfo ## How long it takes to return to normal value after tween

@export_group("Sin")
@export var frequency : float = 25.0
@export var amplitude : float = 1.0

var active_tween : Tween ## Track active tween to prevent spamming
var _sin_time : float = 0.0

## Face the sprite in the direction given (either left or right)
func _face_dir(direction : float):
	if not sprite: return
	sprite.flip_h = (direction < 0) # If direction is greater than 0 flip

## Squash the sprite
func _squash() -> void:
	if not sprite or not squash_tween or not return_tween: return
	_verify_tween()
	
	
	# Tween the sprite's scale
	active_tween.tween_property(sprite, "scale", squash_tween.scale, squash_tween.duration)\
		.set_trans(squash_tween.transition_type).set_ease(squash_tween.easing_style) # Set transition type to selected
	
	_return_from_tween() # Return to default

## Stretch the sprite
func _stretch() -> void:
	if not sprite or not stretch_tween or not return_tween: return
	_verify_tween()
	
	# Tween the sprite's scale
	active_tween.tween_property(sprite, "scale", stretch_tween.scale, stretch_tween.duration)\
		.set_trans(stretch_tween.transition_type).set_ease(stretch_tween.easing_style) # Set transition type to selected
	
	_return_from_tween() # Return to default

## Offset the Y value of the sprite using sin() and delta
func _sprite_sin_offset(delta : float) -> void:
	if not sprite: return
	_sin_time += delta
	sprite.offset.y = (-sin((_sin_time * frequency)) * amplitude) - 1

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
