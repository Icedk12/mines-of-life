class_name SettingsParser extends GridContainer

var settings : Dictionary[String, int] = {}

func _ready() -> void:
	settings.clear()
	$"../../ConfirmBtn".pressed.connect(_update_game_settings)

func _parse() -> void:
	for child in get_children():
		for grandchild in child.get_children():
			if grandchild is HSlider:
				settings[child.get_child(0).text] = grandchild.value

func _update_game_settings() -> void:
	_parse()
	
	GameSettings.render_distance = settings["Chunk Render Distance:"]
	GameSettings.tiles_per_frame_budget = settings["Tiles per frame:"]
	GameSettings.ores_per_frame_budget = settings["Ores per frame:"]
	GameSettings.lights_per_frame_budget = settings["Lights per frame:"]
	GameSettings.unload_chunks_per_frame = settings["Chunk Unload per frame:"]
	GameSettings.unload_buffer = settings["Chunk Unload Buffer:"]
	GameSettings.unload_tiles_per_frame_budget = settings["Unload Tiles per frame:"]
