extends TextureRect

var stored_col : Color

func _ready() -> void:
	$"../PlayerColour".color = Color(randf(), randf(), randf(), 1.0)
	self_modulate = stored_col

func _process(delta: float) -> void:
	stored_col = $"../PlayerColour".color
	stored_col.a = 1.0
	self_modulate = stored_col
