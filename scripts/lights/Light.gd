extends PointLight2D

@export var pulse_speed: float = 0.9
@export var base_scale: float = 0.5
@export var pulse_intensity: float = 0.05

var time_passed: float = 0.0

func _physics_process(delta: float) -> void:
	time_passed += delta * pulse_speed
	texture_scale = base_scale + sin(time_passed) * pulse_intensity
