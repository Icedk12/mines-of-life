extends Node

signal bloom_changed
signal bloom_intensity_changed

var seed_ : int ## Used for map generation and random other stuff
var render_distance : int = 3 ## Chunk render distance, how many chunks far you can see
var chunk_size : int = 16  ## How big the chunks are.

var player_mod : Color
var difficulty : float = 1.0

var tiles_per_frame_budget : int = 128
var ores_per_frame_budget : int = 4   ## how many ore types to roll per frame
var lights_per_frame_budget : int = 128
var unload_chunks_per_frame : int = 1
var unload_buffer : int = 2
var unload_tiles_per_frame_budget : int = 128
var bloom : int  = 0 : set = _set_bloom
var bloom_intensity : float = 3.0 : set = _set_bloom_intensity

func _set_bloom_intensity(val : float) -> void:
	bloom_intensity = val
	bloom_intensity_changed.emit(val)

func _set_bloom(val : int) -> void:
	bloom = val
	bloom_changed.emit(val)
