extends TextureButton
@onready var main : Main = $"../../../.."

@export var hover_speed: float = 2
@export var hover_intensity: float = 0.05

var time_passed: float = 0.0
@onready var start_rotation: float = rotation

@onready var confirm_btn : Button = $"../StartMenu/StartButton"
@onready var StartMenu : Control = $"../StartMenu"

var first_press : bool = true
var editing_options : bool = false

func _ready() -> void:
	pivot_offset = size / 2

func _on_pressed() -> void:
	if not first_press: return
	first_press = false
	StartMenu.visible = true

func _physics_process(delta: float) -> void:
	time_passed += delta * hover_speed
	rotation = start_rotation + (sin(time_passed) * hover_intensity)

func _confirm_pressed() -> void:
	GameSettings.render_distance = int($"../StartMenu/SimulationDistance".text)
	GameSettings.seed_ = int($"../StartMenu/Seed".text)
	GameSettings.chunk_size = int($"../StartMenu/ChunkSize".text)
	main.player.sprite.self_modulate = $"../StartMenu/PlayerColour".color
	main.player.light.set_mult(float($"../StartMenu/Darkness".text))
	
	# Nah seed 0 get out!!
	if GameSettings.seed_ == 0:
		GameSettings.seed_ = randi()
	
	StartMenu.visible = false
	$Label.text = "LOADING"
	main.level.level_generator.generate_initial_world()
