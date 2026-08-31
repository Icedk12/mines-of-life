extends Label

# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	var fps = Engine.get_frames_per_second()
	text = "FPS: " + str(fps)
