extends TextureButton
@onready var main : Main = $"../../.."

var inital : bool = true

func _on_pressed() -> void:
	if not inital: return
	main.level.level_generator.generate_initial_world()
	$Label.text = "LOADING..."
