extends Label

func _process(delta: float) -> void:
	text = "SEED: " + str(GameSettings.seed_)
	Utils.wait_frames(60)
