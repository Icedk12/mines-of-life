class_name BlockSetting extends Resource

@export var block_id : int
@export var terrain_set_id : int = 0 ## which terrain set, most stuff is just 0
@export var terrain_id : int = 0      ## which terrain in the TileSet this block autotiles as
@export var gen_chance : float = 1.0 ## if an ore then how rare it is to generate
@export var max_size : int = 1 ## How many blocks can spawn in single vein
@export var min_size : int = 1

enum ShapeType { VEIN, PENNY_BLOCK }
@export var shape_type : ShapeType = ShapeType.VEIN ## The generation shape for blocks, custom ore shapes
