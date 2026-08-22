extends TextureButton
@onready var mainmenu = $"../.."
@onready var main = $"../../.."

func _on_pressed() -> void:
	main.player.State = get_parent().player.State.PLAYING
	mainmenu.queue_free()
