class_name AudioSourceComponent
extends CharacterComponent

@export_group("Audio")
@export var audio_player : AudioStreamPlayer2D
@export var footstep_sounds : Array[AudioStream] = []
@export var voice_pool_size : int = 8

var _voices : Array[AudioStreamPlayer2D] = []
var _next_voice : int = 0

func _ready() -> void:
	if not audio_player:
		return
	for i in voice_pool_size:
		var v := AudioStreamPlayer2D.new()
		v.bus = audio_player.bus
		v.attenuation = audio_player.attenuation
		v.max_distance = audio_player.max_distance
		add_child(v)
		_voices.append(v)

func play_footstep() -> void:
	_play_sound(footstep_sounds)

func play_sound(sounds : Array[AudioStream]) -> void:
	_play_sound(sounds)

func _play_sound(sounds : Array[AudioStream]) -> void:
	if _voices.is_empty() or sounds.is_empty():
		return

	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()

	voice.global_position = get_parent().global_position
	voice.stream = sounds[randi() % sounds.size()]
	voice.pitch_scale = randf_range(0.95, 1.05)
	voice.play()
