class_name CharacterComponent extends Component

@export var character : Player ## [OPTIONAL]

func _ready() -> void:
	if character == null:
		character = get_parent() as Player

func _is_character_null() -> bool:
	return character == null
