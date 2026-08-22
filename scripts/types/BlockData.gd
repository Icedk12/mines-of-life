class_name BlockData extends Resource

@export var block_id : int
@export var display_name : String
@export var terrain_set_id : int = 0
@export var terrain_id : int = 0      ## which terrain in the TileSet this block autotiles as

@export var hardness : int = 3
@export var required_strength : int = 0
@export var wobble_amplitude : float = 2.0
@export var wobble_duration : float = 0.06

@export_group("Audio") ## sound played when hit/broken 67
@export var hit_sounds : Array[AudioStream] = []
@export var place_sounds : Array[AudioStream] = []