extends Label

func _process(delta: float) -> void:
	text = "SEED: " + str(GameSettings.seed_)
	wait_frames(60)

func wait_frames(number_of_frames: int):
	for i in range(number_of_frames):
		await get_tree().process_frame
