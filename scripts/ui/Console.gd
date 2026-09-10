extends Window

@export var main : Main
@export var output_log: RichTextLabel
@export var input_line: LineEdit

var commands: Dictionary = {}

func _ready() -> void:
	hide()
	close_requested.connect(_on_close_requested)
	input_line.text_submitted.connect(_on_text_submitted)

	set_process_input(true)

	register_command("c_l", _cmd_contrib, "Lists all credits and license.")
	
	register_command("help", _cmd_help, "Lists all available commands.")
	register_command("cls", _cmd_clear, "Clears the console log.")
	register_command("cheats", _cmd_cheats, "Enables or disables cheats, enter true or false.")
	register_command("reload", _cmd_reload, "Reloads current scene.")

	
	register_command("clr_wd", _cmd_clear_world_data, "Clears world cache in AppData.")
	register_command("wd_settings", _cmd_world_settings, "Prints out world settings.")
	
	register_command("pl_settings", _cmd_player_settings, "Lists player settings.")
	register_command("heal", _cmd_heal, "Heals player x health, enter a number.")
	register_command("dmg", _cmd_damage, "Damages player x health, enter a number.")
	register_command("zoom", _cmd_zoom, "Sets player camera zoom.")
	register_command("xp", _cmd_add_xp, "Adds XP to the player.")


func toggle_console() -> void:
	if visible:
		hide()
		input_line.clear()
	else:
		popup_centered()
		input_line.clear()
		input_line.grab_focus()

## Registers a command. Callback must accept sn array of strings as its only parameter.
func register_command(command_name: String, callback: Callable, description: String = "") -> void:
	commands[command_name.to_lower()] = {
		"callback": callback,
		"description": description
	}

func log_message(text: String) -> void:
	output_log.append_text(text + "\n")

func _on_text_submitted(input_text: String) -> void:
	input_line.clear()
	
	var trimmed := input_text.strip_edges()
	if trimmed.is_empty():
		return
		
	log_message("[color=gray]> " + trimmed + "[/color]")
	
	# Parse command name and arguments
	var parts := trimmed.split(" ", false)
	var cmd_name := parts[0].to_lower()
	var args: Array[String] = []
	
	for i in range(1, parts.size()):
		args.append(parts[i])
		
	if commands.has(cmd_name):
		commands[cmd_name]["callback"].call(args)
	else:
		log_message("[color=red]Unknown command: '" + cmd_name + "'. Type 'help' for available commands.[/color]")

func _on_close_requested() -> void:
	hide()

func validate_args(_args: Array[String]) -> void:
	if _args.size() == 0:
		log_message("no argument provided")
		return

########################## COMMANDS ########################

func _cmd_help(_args: Array[String]) -> void:
	log_message("[color=yellow]Available Commands:[/color]")
	for cmd in commands:
		var desc: String = commands[cmd]["description"]
		log_message(" - [b]" + cmd + "[/b]: " + desc)

func _cmd_clear(_args: Array[String]) -> void:
	output_log.clear()
	log_message("#   # ### #   # #####  ####     ###  #####    #     ### ##### ##### 
## ##  #  ##  # #     #        #   # #        #      #  #     #     
# # #  #  # # # ####   ###     #   # ####     #      #  ####  ####  
#   #  #  #  ## #         #    #   # #        #      #  #     #     
#   # ### #   # ##### ####      ###  #        ##### ### #     ##### ")

func _cmd_world_settings(_args: Array[String]) -> void:
	log_message("seed: %s" % GameSettings.seed_)
	log_message("render_distance: %s" % GameSettings.render_distance)
	log_message("chunk_size: %s" % GameSettings.chunk_size)
	log_message("difficulty: %s" % GameSettings.difficulty)

func _cmd_clear_world_data(_args: Array[String]) -> void:
	var prev_size_str := ChunkStorage.get_folder_size("user://world_saves")
	DirAccess.remove_absolute("user://world_saves")
	log_message("clearing world cache...")
	log_message("%s bytes cleared" % prev_size_str)

func _cmd_player_settings(_args: Array[String]) -> void:
	log_message("hex: %s" % GameSettings.player_mod)
	log_message("cheats: %s" % GameSettings.cheats)

func _cmd_cheats(_args: Array[String]) -> void:
	validate_args(_args)
	GameSettings.cheats = true if _args[0] == "true" else false
	log_message("set cheats to: %s" % GameSettings.cheats)

func _cmd_heal(_args: Array[String]) -> void:
	validate_args(_args)
	if not GameSettings.cheats:
		log_message("cheats are not enabled. use 'cheats' to enable")
		return
		
	if not _args[0].is_valid_int() and not _args[0].is_valid_float():
		log_message("invalid heal amount")
	main.player.health_component.heal(float(_args[0]))
	log_message("healed player by %s health" % _args[0])
	
func _cmd_damage(_args: Array[String]) -> void:
	validate_args(_args)
	if not GameSettings.cheats:
		log_message("cheats are not enabled. use 'cheats' to enable")
		return
		
	if not _args[0].is_valid_int() and not _args[0].is_valid_float():
		log_message("invalid damage amount")
	
	main.player.health_component.take_damage(float(_args[0]))
	log_message("damaged player by %s health" % _args[0])

func _cmd_reload(_args: Array[String]) -> void:
	log_message("restarting current scene")
	get_tree().reload_current_scene()

func _cmd_zoom(_args: Array[String]) -> void:
	validate_args(_args)
	
	if not _args[0].is_valid_int() and not _args[0].is_valid_float():
		log_message("invalid zoom amount")
	
	main.player.camera.zoom = Vector2(float(_args[0]), float(_args[0]))
	log_message("zoomed camera to %s" % Vector2(float(_args[0]), float(_args[0])))

func _cmd_add_xp(_args: Array[String]) -> void:
	validate_args(_args)
	
	if not _args[0].is_valid_int() and not _args[0].is_valid_float():
		log_message("invalid xp amount")
	
	main.player.xp_component.add_xp(float(_args[0]))
	log_message("gave %s xp to player" % _args[0])

func _cmd_contrib(_args: Array[String]) -> void:
	_cmd_clear(_args)
	log_message("All source code under copyright of NVCCS Studios (c).")
	log_message("")
	log_message("Source Code: Tom Patton-Low")
	log_message("Graphics: Harry Patton-Low")
	log_message("Pathfinding Algorithm: Peter Hart, Nils Nilsson, and Bertram Raphael")
	log_message("")
	log_message("Honourable Mentions:")
	log_message("\t- Luke Woolhouse")
	log_message("\t- Jaydn Nelson")
	log_message("\t- Jay Hammond")
	log_message("\t- Noah Turner")
	log_message("\t- Corbin Gill")
	log_message("")
	log_message("Software used:")
	log_message("\t- Git")
	log_message("\t- Aesprite")
	log_message("\t- Godot 4.7, 4.6")
	log_message("\t- Trello")
	log_message("\t- Google Docs")
