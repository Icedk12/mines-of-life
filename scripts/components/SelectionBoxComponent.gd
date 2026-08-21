class_name SelectionBoxComponent extends CharacterComponent

@export var mine_component : MineComponent
@export var sprite : Sprite2D
@export var tween_duration: float = 0.1 ## Speed of tween

var selected_tile_global_pos : Vector2:
	set(value):
		if selected_tile_global_pos != value:
			selected_tile_global_pos = value
			_tween_to_position(selected_tile_global_pos)
func _tween_to_position(target_pos: Vector2) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "global_position", target_pos, tween_duration)
