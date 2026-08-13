extends Node2D

@export var player : Player

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_teleport"):
		player.global_position = get_local_mouse_position()
