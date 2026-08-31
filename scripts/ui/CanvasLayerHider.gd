extends CanvasLayer

func _cutscene_started() -> void:
	visible = false

func _cutscene_ended() -> void:
	visible = true
