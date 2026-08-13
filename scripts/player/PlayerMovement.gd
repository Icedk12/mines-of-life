class_name PlayerMovement extends Component

var stats : StatContainer

func _is_player_child() -> void:
	super._is_player_child()
	if player:
		stats = player.stats

func _physics_process(delta: float) -> void:
	if not player or not stats:
		return

	# Add gravity
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		player.velocity.y = -stats.default_jump_velocity

	# Handle horizontal movement
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0:
		player.velocity.x = direction * stats.default_walkspeed
	else:
		# Use friction/deceleration stat to slow down properly
		player.velocity.x = move_toward(player.velocity.x, 0, stats.default_deceleration)

	player.move_and_slide()
