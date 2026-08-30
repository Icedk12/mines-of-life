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
@export var hit_sounds : Array[AudioStream] = []
@export var place_sounds : Array[AudioStream] = []
