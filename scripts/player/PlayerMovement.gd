class_name PlayerMovement extends Component

@onready var player : CharacterBody2D
var stats : StatContainer

func _ready() -> void:
	stats = player.stats

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		player.velocity.y = stats.default_walkspeed

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		player.velocity.x = direction * stats.default_walkspeed
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, delta)

	player.move_and_slide()
