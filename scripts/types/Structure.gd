class_name StructureDefinition extends Resource
 
@export var scene : PackedScene ## Scene whose root (or a nested child) is a TileMapLayer painted with this structure.
@export_range(0.0, 1.0, 0.001) var spawn_chance : float = 0.05 ## Chance, per chunk, that THIS structure attempts to spawn.
 
@export var min_spacing : int = 32 ## tiles between two structures of SAME type
@export var placement_attempts : int = 1
