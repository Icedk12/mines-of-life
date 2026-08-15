class_name InputAxisComponent extends InputComponent

@export_category("Inputs")
@export var left : String = "move_left"
@export var right : String = "move_right"

func _get_input_direction() -> float:
	return Input.get_axis(left, right)
