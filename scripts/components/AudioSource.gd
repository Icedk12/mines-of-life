class_name AudioSourceComponent
extends CharacterComponent

@export_group("Audio")
@export var audio_player : AudioStreamPlayer2D
@export var footstep_sounds : Array[AudioStream] = []

func play_footstep() -> void:
	_play_sound(footstep_sounds)

## pass the array of hit/break sounds
func play_sound(sounds : Array[AudioStream]) -> void:
	_play_sound(sounds)

func _play_sound(sounds : Array[AudioStream]) -> void:
	if not audio_player or sounds.is_empty(): return
	audio_player.stream = sounds[randi() % sounds.size()]
	audio_player.pitch_scale = randf_range(0.95, 1.05)
	audio_player.play()
