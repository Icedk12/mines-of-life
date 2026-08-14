class_name CharacterComponent extends Component

@export var character : CharacterBody2D ## Mutually exclusive with isCharChild. (Retard proof)
@export var is_char_child : bool = false ## Tick when the component is the child of a character, it will then automatically assign it to the player internal variable.

func _ready() -> void:
	if not character == null:
		# If char was selected in @export
		is_char_child = false
	
	if is_char_child:
		_is_char_child()

func _is_char_child() -> void:
	character = get_parent() as CharacterBody2D
