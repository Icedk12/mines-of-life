extends TextureRect

@export var hover_speed: float = 2
@export var hover_intensity: float = 0.05

var time_passed: float = 0.0
@onready var start_rotation: float = rotation

func _physics_process(delta: float) -> void:
	time_passed += delta * hover_speed
	rotation = start_rotation + (sin(time_passed) * hover_intensity)
