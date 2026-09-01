class_name BlockData extends Resource

@export var atlas_terrain_index: int = 0
@export var block_id : int
@export var display_name : String
@export var terrain_set_id : int = 0
@export var terrain_id : int = 0      ## which terrain in the TileSet this block autotiles as

@export var hardness : int = 3
@export var required_strength : int = 0
@export var wobble_amplitude : float = 2.0
@export var wobble_duration : float = 0.06

@export_group("Drops")
@export var block_only : bool = true ## If true the block only drops the item with its block id
@export var drop_ids : Array[int]
@export var drop_amount : Array[int]
@export var drop_scarcity : Array[int] ## Chance for each drop to not drop, if zero its guarentteed

@export_group("Audio") ## sound played when hit/broken
const DEFAULT_HIT: Array[AudioStream] = [
	preload("res://assets/sounds/hit.mp3")
]
const DEFAULT_PLACE: Array[AudioStream] = [
	preload("res://assets/sounds/hit.mp3")
]

@export var hit_sounds: Array[AudioStream] = DEFAULT_HIT.duplicate()
@export var place_sounds: Array[AudioStream] = DEFAULT_PLACE.duplicate()

## Helper functions to fetch audio
func get_hit_sounds() -> Array[AudioStream]:
	if not hit_sounds.is_empty():
		return hit_sounds
	return DEFAULT_HIT

func get_place_sounds() -> Array[AudioStream]:
	if not place_sounds.is_empty():
		return place_sounds
	return DEFAULT_PLACE