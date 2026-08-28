class_name LayerData extends Resource

## Must be unique across all LayerDatas
@export var layer_id : LayerType.Layer
@export var display_name : String = ""

## Bounds are in tile coords not pixels
@export_group("Bounds")
@export var inf_x : bool = true
@export var inf_y : bool = false
@export var x_left : int = 0
@export var x_right : int = 0
@export var y_top : int = 0
@export var y_bottom : int = 0

@export_group("Terrain")
@export var terrain_set_id : int = 0
@export var terrain_id : int = 0
@export_range(0.0, 1.0, 0.01) var tile_generate_chance : float = 0.25 ## Higher = more open/carved out
@export var noise_frequency : float = 0.03
@export var noise_fractal_type : FastNoiseLite.FractalType = FastNoiseLite.FRACTAL_FBM

## Ores (added to level generator)
@export_group("Ore Generation")
@export var ores : Array[BlockSetting] = []

## Structures (added to level generator)
@export_group("Structures")
@export var structures : Array[StructureDefinition] = []

@export_group("Enemies")
@export var enemy_pool : Array[EnemySpawnEntry] = []
@export var max_enemies_per_chunk : int = 2
@export_range(0.0, 1.0, 0.01) var spawn_chance_per_chunk : float = 0.1 ## Rolled once per chunk generated in this layer

## Whether the given world/tile position falls inside this layer's bounds.
func is_in_layer(pos : Vector2) -> bool:
	if not inf_x and (pos.x < x_left or pos.x > x_right):
		return false
	if not inf_y and (pos.y < y_top or pos.y > y_bottom):
		return false
	return true

func get_vertical_span() -> float:
	if inf_y:
		return INF
	return float(y_bottom - y_top)

## Picks a random entry from enemy_pool, weighted by .weight. Returns null if the pool is empty.
func pick_random_enemy() -> EnemySpawnEntry:
	if enemy_pool.is_empty():
		return null

	var total_weight := 0.0
	for e in enemy_pool:
		total_weight += e.weight
	if total_weight <= 0.0:
		return null

	var roll := randf() * total_weight
	for e in enemy_pool:
		roll -= e.weight
		if roll <= 0.0:
			return e
	return enemy_pool.back()
