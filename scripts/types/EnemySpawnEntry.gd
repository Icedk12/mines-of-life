class_name EnemySpawnEntry extends Resource
 
@export var enemy_scene : PackedScene
@export_range(0.01, 100.0, 0.01) var weight : float = 1.0 ## Chance vs other entries in the same pool
@export var min_group_size : int = 1
@export var max_group_size : int = 1
