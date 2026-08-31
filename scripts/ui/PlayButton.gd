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
	var tween : Tween = create_tween().set_trans(Tween.TRANS_EXPO)
	tween.tween_property($"../StartMenu", "position", Vector2(-6.25, 2), 0.8)
 
func _physics_process(delta: float) -> void:
	time_passed += delta * hover_speed
	rotation = start_rotation + (sin(time_passed) * hover_intensity)
 
func _confirm_pressed() -> void:
	var tween : Tween = create_tween().set_trans(Tween.TRANS_EXPO)
	tween.tween_property($"../StartMenu", "position", Vector2(-6.25, 244.5), 0.8)
 
	GameSettings.render_distance = int($"../StartMenu/SimulationDistance".text)
	GameSettings.chunk_size = int($"../StartMenu/ChunkSize".text)
	GameSettings.player_mod = $"../StartMenu/PlayerColour".color
	main.player.sprite.self_modulate = GameSettings.player_mod
	main.player.light.set_mult(float($"../StartMenu/Darkness".text))
	if $"../StartMenu/MiningEasy".selected == 0:
		main.player.mine_component.hit_amount = 1000
		main.player.mine_component.cd_timer.wait_time = 0.01
		main.player.mine_component.trauma = 0.05
	
	if not $"../StartMenu/Seed".text.is_valid_int():
		GameSettings.seed_ = randi()
	else:
		GameSettings.seed_ = int($"../StartMenu/Seed".text)
	
	ChunkStorage.clear_world(GameSettings.seed_)
	$Label.text = "LOADING"
	main.level.level_generator.generate_initial_world()
 
