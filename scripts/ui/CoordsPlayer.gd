extends Label

func _process(delta: float) -> void:
	text = "COORDINATES: (" + str(int($"..".player.global_position.x / 10)) + ", " + str(int($"..".player.global_position.y / 10)) + ")"
