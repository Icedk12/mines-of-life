class_name MusicPlayer extends AudioStreamPlayer

@export var playlist: Array[AudioStream] = []

@export var min_delay: float = 3.0
@export var max_delay: float = 10.0

@export var shuffle_tracks: bool = true

@export var wait_timer: Timer

var _current_index: int = 0

func _ready() -> void:
	# Connect signals via code
	finished.connect(_on_song_finished)
	wait_timer.timeout.connect(_on_timer_timeout)
	
	if playlist.is_empty():
		push_warning("BGMPlayer: Playlist is empty! Please add audio streams.")
		return
		
	if shuffle_tracks:
		playlist.shuffle()
		

func _play_next_track() -> void:
	if playlist.is_empty():
		return
		
	stream = playlist[_current_index]
	play()
	
	_current_index = (_current_index + 1) % playlist.size()
	
	if _current_index == 0 and shuffle_tracks:
		playlist.shuffle()

func _on_song_finished() -> void:
	var random_wait_time = randf_range(min_delay, max_delay)
	
	wait_timer.wait_time = random_wait_time
	wait_timer.start()

func _on_timer_timeout() -> void:
	_play_next_track()
