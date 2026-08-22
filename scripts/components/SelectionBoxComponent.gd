class_name SelectionBoxComponent extends CharacterComponent

@export var mine_component : MineComponent
@export var sprite : Sprite2D
@export var tween_duration: float = 0.1 ## Speed of tween

var fade_tween : Tween

var selected_tile_global_pos : Vector2:
	set(value):
		if selected_tile_global_pos != value:
			selected_tile_global_pos = value
			_tween_to_position(selected_tile_global_pos)
			
func _tween_to_position(target_pos: Vector2) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "global_position", target_pos, tween_duration)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("select_cursor_toggle"):
		_set_visible_with_fade(sprite.visible)

func _set_visible_with_fade(should_hide: bool) -> void:
	if fade_tween and fade_tween.is_running():
		fade_tween.kill()
		
	fade_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	if should_hide:
		fade_tween.tween_property(sprite, "self_modulate", Color.TRANSPARENT, 0.3)
		fade_tween.tween_callback(func(): sprite.visible = false)
	else:
		sprite.visible = true
		fade_tween.tween_property(sprite, "self_modulate", Color.WHITE, 0.3)
