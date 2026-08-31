extends Node

@export var layers : Array[LayerData] = []
var _by_id : Dictionary[int, LayerData] = {} ## keyed by LayerType.Layer (int)

func _ready() -> void:
	for l in layers:
		if _by_id.has(l.layer_id):
			push_warning("Duplicate layer_id %s — earlier LayerData will be shadowed by get_layer_by_id()" % LayerType.Layer.keys()[l.layer_id])
		_by_id[l.layer_id] = l

func get_layer_by_id(id: LayerType.Layer) -> LayerData:
	return _by_id.get(id)

func get_layer_for_position(pos: Vector2) -> LayerData:
	var best : LayerData = null
	var best_span : float = INF
	for l in layers:
		if l.is_in_layer(pos):
			var span := l.get_vertical_span()
			if span < best_span:
				best = l
				best_span = span
	return best

## Convenience overload for Vector2i tile positions.
func get_layer_for_tile(tile_pos: Vector2i) -> LayerData:
	return get_layer_for_position(Vector2(tile_pos.x, tile_pos.y))
