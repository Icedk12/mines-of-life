class_name Level extends Node2D

@export var music_player : MusicPlayer
@export var main_menu : Node2D
@export var player : Player
@export var level_generator : LevelGenerator
@export var _layer1 : TileMapLayer

func finished_generation_inital() -> void:
	music_player._play_next_track()
	level_generator.modify_tile(Vector2i(0, 0), false)
	level_generator.modify_tile(Vector2i(1, 0), false)
	level_generator.modify_tile(Vector2i(0, 1), false)
	level_generator.modify_tile(Vector2i(-1, 0), false)
	level_generator.modify_tile(Vector2i(0, -1), false)
	level_generator.modify_tile(Vector2i(1, 1), false)
	level_generator.modify_tile(Vector2i(-1, -1), false)
	level_generator.modify_tile(Vector2i(-1, 1), false)
	level_generator.modify_tile(Vector2i(1, -1), false)
	
	player.start_player()
	main_menu.queue_free()
