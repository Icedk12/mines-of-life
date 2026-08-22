class_name Main extends Node2D

@export var player : Player
@export var level : Node2D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_teleport") and not player.state == player.State.MAIN_MENU:
		player.global_position = get_local_mouse_position()
