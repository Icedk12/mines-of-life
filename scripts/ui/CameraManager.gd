class_name ShakeableCamera2D extends Camera2D

@export var decay := 0.8  # Speed the shake stops
@export var max_offset := Vector2(100, 75)  # Max distance in pixels
@export var max_roll := 0.1  # Max rotation in radians
@export var trauma_power := 2  # Increases shake curve tightness

var trauma := 0.0
var noise := FastNoiseLite.new()
var noise_y := 0

func _ready() -> void:
	randomize()
	noise.seed = randi()
	noise.frequency = 2.0

func add_trauma(amount: float) -> void:
	trauma = min(trauma + amount, 1.0)

func _process(delta: float) -> void:
	if trauma > 0:
		trauma = max(trauma - decay * delta, 0.0)
		shake()
	else:
		offset = Vector2.ZERO
		rotation = 0.0

func shake() -> void:
	var amt = pow(trauma, trauma_power)
	noise_y += 1
	offset = max_offset * amt * Vector2(noise.get_noise_2d(noise_y, 0), noise.get_noise_2d(0, noise_y))
	rotation = max_roll * amt * noise.get_noise_2d(noise_y, noise_y)
