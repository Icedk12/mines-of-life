class_name CharacterComponent extends Component

@export var character : CharacterBody2D ## [OPTIONAL]

func _ready() -> void:
	if character == null:
		character = get_parent() as CharacterBody2D
