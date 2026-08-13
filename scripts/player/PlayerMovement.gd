class_name PlayerMovement extends Component

var stats: StatContainer
@export var sprite: Sprite2D

var was_on_floor: bool = true
var active_tween: Tween  ## Track active tween to prevent spamming

func _is_player_child() -> void:
	super._is_player_child()
	if player:
		stats = player.stats

func _physics_process(delta: float) -> void:
	if not player or not stats:
		return

	# Apply gravity
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		player.velocity.y = -stats.default_jump_velocity

	# Handle horizontal movement & sprite flipping
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0:
		player.velocity.x = direction * stats.default_walkspeed
		if sprite:
			sprite.flip_h = (direction < 0)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, stats.default_deceleration)

	# 1. Run physics update FIRST
	player.move_and_slide()

	# 2. Check landing condition AFTER physics update
	var is_currently_on_floor := player.is_on_floor()
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
		_animate_scale(Vector2(1.6, 0.8), 0.1) # Squash on land, then recover
		return

	# --- AIRBORNE STATES ---
	if not player.is_on_floor():
		_animate_scale(Vector2(0.9, 1.1), 0.15) # Stretch while falling
		return

	# --- GROUND STATES ---
	if abs(player.velocity.x) > 10.0:
		pass
	else:
		# Use approx comparison to avoid floating-point issues
		if not sprite.scale.is_equal_approx(Vector2.ONE):
			_animate_scale(Vector2.ONE, 0.15)

## Helper method to safely stop previous tweens before starting a new one
func _animate_scale(target_scale: Vector2, duration: float) -> void:
	if active_tween and active_tween.is_running():
		active_tween.kill()

	active_tween = create_tween()
	active_tween.tween_property(sprite, "scale", target_scale, duration)
