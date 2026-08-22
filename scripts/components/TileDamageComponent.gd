class_name TileDamageComponent extends CharacterComponent

@export var overlay_sprite : Sprite2D
@export var crack_frames : Array[Texture2D]

var active_tween : Tween
var base_position : Vector2 ## the tile's actual global position, untouched by wobble

func play_hit(tile_pos: Vector2i, hits: int, max_hits: int, block_data: BlockData) -> void:
	if not overlay_sprite: return

	base_position = character.level.level_generator.tilemap.to_global(tile_pos * 8) + Vector2(4, 4)
	
	# Set the position to the tile, and reset the OFFSET instead of the local position
	overlay_sprite.global_position = base_position
	overlay_sprite.offset.x = 0.0 
	overlay_sprite.visible = true

	var stage = int(float(hits) / max_hits * (crack_frames.size() - 1))
	overlay_sprite.texture = crack_frames[stage]

	_wobble(block_data)

func _wobble(block_data: BlockData) -> void:
	if active_tween and active_tween.is_running():
		active_tween.kill()

	active_tween = create_tween()
	var amp = block_data.wobble_amplitude
	var d = block_data.wobble_duration
	
	# Tween the offset:x instead of position:x
	active_tween.tween_property(overlay_sprite, "offset:x", amp, d).set_trans(Tween.TRANS_SINE)
	active_tween.tween_property(overlay_sprite, "offset:x", -amp, d).set_trans(Tween.TRANS_SINE)
	active_tween.tween_property(overlay_sprite, "offset:x", 0.0, d).set_trans(Tween.TRANS_SINE)
func clear() -> void:
	if active_tween and active_tween.is_running():
		active_tween.kill()
	if overlay_sprite:
		overlay_sprite.visible = false
