class_name SpriteModifierComponent extends CharacterComponent

@export_group("Objects")
@export var sprite : Sprite2D ## Character's sprite you want to modify

@export_group("Tweens")
@export var squash : Vector2 = Vector2.ONE
@export var squash_duration : float = 0.5
@export var squash_transition : Tween.TransitionType = Tween.TRANS_QUAD

@export var stretch : Vector2 = Vector2.ONE
@export var stretch_duration : float = 0.5
@export var stretch_transition : Tween.TransitionType = Tween.TRANS_QUAD

@export var return_duration : float = 1.0 ## How long it takes to return to normal value after tween

@export_group("Sin")
@export var frequency : float = 10.0
@export var amplitude : float = 1.0
@export var starting_value : float = 0

var active_tween : Tween ## Track active tween to prevent spamming

## Face the sprite in the direction given (either left or right)
func _face_dir(direction : float):
	if not sprite: return
	sprite.flip_h = (direction < 0) # If direction is greater than 0 flip

## Squash the sprite
func _squash() -> void:
	if not sprite: return
	_verify_tween()
	
	# Tween the sprite's scale
	active_tween.tween_property(sprite, "scale", squash, squash_duration)\
		.set_trans(squash_transition).set_ease(Tween.EASE_OUT) # Set transition type to selected
	
	_return_from_tween() # Return to default

## Stretch the sprite
func _stretch() -> void:
	if not sprite: return
	_verify_tween()
	
	# Tween the sprite's scale
	active_tween.tween_property(sprite, "scale", stretch, stretch_duration)\
		.set_trans(stretch_transition).set_ease(Tween.EASE_OUT) # Set transition type to selected
	
	_return_from_tween() # Return to default

## Offset the Y value of the sprite using sin() and delta
func _sin_offset(delta : float) -> void:
	sprite.offset.y = -sin(frequency * delta) * amplitude

# ============= HELPER FUNCTIONS ============= #
## Tweens the sprite to Vector2.ONE, aka default scale
func _return_from_tween() -> void:
	active_tween.tween_property(sprite, "scale", Vector2.ONE, return_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

## Helper function to kill the tween if its already running
func _verify_tween() -> void:
	# ^^^^^^ Hey it's me its verity 😃
	# ayo nah verity gtfo my code
	#
	# for i in range(64):
	# 	print("Larp")
	
	if active_tween and active_tween.is_running():
		active_tween.kill()
