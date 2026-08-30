extends WorldEnvironment

func _ready() -> void:
	GameSettings.bloom_changed.connect(_on_bloom)
	GameSettings.bloom_intensity_changed.connect(_on_bloom_intensity)

func _on_bloom(val : int) -> void:
	match val:
		0:
			environment.glow_enabled = false
		1:
			environment.glow_enabled = true

func _on_bloom_intensity(val : float) -> void:
	environment.glow_intensity = val
