class_name InventoryLabel extends Label

@export var tween_duration: float = 1.0

var target_color : Color = Color.WHITE
var current_tween : Tween
var stack_size : String

func set_text_value(new_text: String) -> void:
	text = new_text
	
	var new_target = Color.RED if text == stack_size else Color.WHITE
	
	if new_target != target_color:
		target_color = new_target
		print()
		
		# Kill any active tween
		if current_tween and current_tween.is_running():
			current_tween.kill()
			
		current_tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		current_tween.tween_property(self, "self_modulate", target_color, tween_duration)
