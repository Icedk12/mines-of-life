extends Node

func wait_frames(number_of_frames: int):
	for i in range(number_of_frames):
		await get_tree().process_frame
