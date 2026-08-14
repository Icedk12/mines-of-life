class_name MovementComponent extends CharacterComponent

@export var stats: StatComponent
@export var sprite: Sprite2D

var was_on_floor: bool = true
var active_tween: Tween  ## Track active tween to prevent spamming

func _physics_process(delta: float) -> void:
	if not character or not stats:
		return

	# Handle jump
	if Input.is_action_just_pressed("jump") and character.is_on_floor():
		character.velocity.y = -stats.default_jump_velocity
		_animate_scale(Vector2(1.0, 1.6), 0.2)

	# Handle horizontal movement & sprite flipping
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0:
		character.velocity.x = direction * stats.default_walkspeed
		if sprite:
			sprite.flip_h = (direction < 0)
	else:
		character.velocity.x = move_toward(character.velocity.x, 0, stats.default_deceleration)

	# Run physics update FIRST
	character.move_and_slide()

	# Check landing condition AFTER physics update
	var is_currently_on_floor := character.is_on_floor()
	var just_landed := not was_on_floor and is_currently_on_floor

	# 3. Update sprite visual state
	_update_sprite_state(just_landed)

	# 4. Save state for next frame
	was_on_floor = is_currently_on_floor

func _update_sprite_state(just_landed: bool) -> void:
	if not sprite:
		return

	# --- LANDING ---
	if just_landed:
		_animate_landing()
		return

	# Don't interrupt the landing squash/recovery while it's playing
	if active_tween and active_tween.is_running() and active_tween.get_meta("is_landing", false):
		return

	# --- AIRBORNE STATES ---
	if not character.is_on_floor():
		_animate_scale(Vector2(0.9, 1.2), 0.15) # Stretch while falling
		return

	# --- GROUND STATES ---
	if abs(character.velocity.x) <= 10.0:
		if not sprite.scale.is_equal_approx(Vector2.ONE):
			_animate_scale(Vector2.ONE, 0.15)
	else:
		pass # TODO: Moving

## Specialized animation sequence for landing
func _animate_landing() -> void:
	if active_tween and active_tween.is_running():
		active_tween.kill()

	active_tween = create_tween()
	active_tween.set_meta("is_landing", true) # Mark this tween as a landing animation
	
	# Squash
	active_tween.tween_property(sprite, "scale", Vector2(1.6, 0.8), 0.08)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Recover back to normal size
	active_tween.tween_property(sprite, "scale", Vector2.ONE, 0.1)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

## Helper method to safely stop previous tweens before starting a new one
func _animate_scale(target_scale: Vector2, duration: float) -> void:
	# Avoid restarting the tween if we are already scaling towards the target
	if sprite.scale.is_equal_approx(target_scale):
		return

	if active_tween and active_tween.is_running():
		active_tween.kill()

	active_tween = create_tween()
	active_tween.tween_property(sprite, "scale", target_scale, duration)
