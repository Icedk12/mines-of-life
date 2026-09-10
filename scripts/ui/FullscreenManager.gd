extends Node

signal setup_complete

@export var control : Control
@export var player : Player

enum Mode {
	PC,
	LAPTOP
}

var inventory_ui_default_pos : Vector2
var setting_ui_default_pos : Vector2
var device_mode : Mode = Mode.PC

func _ready() -> void:
	await get_tree().process_frame
	if player == null: return
	if control == null: return
	if player.player_gui == null or player.player_gui.inventory_ui == null: return

	var ui = player.player_gui.inventory_ui
	var viewport_size : Vector2i = Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))
	device_mode = Mode.PC if viewport_size == Vector2i(1920, 1080) else Mode.LAPTOP
	
	match device_mode:
		Mode.LAPTOP:
			control.scale = Vector2(2.4, 2.4)
			control.position = Vector2(-82, -137)
			player.player_gui.scale = Vector2(0.67, 0.67)
			player.player_gui.size = Vector2(1719, 967)
			player.camera.zoom = Vector2(2.5, 2.5)
			ui.inventory_panel.scale = Vector2(0.67, 0.67)
			
			ui.inv_active_position = Vector2(525, 513)
			ui.set_active_position = Vector2(525, 513)
			
			ui.inv_disabled_position = Vector2(525, 1000)
			ui.set_disabled_position = Vector2(525, 1000)
			
			inventory_ui_default_pos = ui.inv_disabled_position
			setting_ui_default_pos = ui.set_disabled_position
		
		Mode.PC:
			control.scale = Vector2(4, 4)
			control.position = Vector2(-136, -231)
			player.player_gui.size = Vector2(1719, 967)
			player.player_gui.scale = Vector2.ONE
			player.player_gui.size = Vector2(1920, 1080)
			player.camera.zoom = Vector2(4, 4)
			ui.inventory_panel.scale = Vector2.ONE
			
			ui.inv_active_position = Vector2(460, 408)
			ui.set_active_position = Vector2(460, 315)
			
			ui.inv_disabled_position = Vector2(460, 1134)
			ui.set_disabled_position = Vector2(460, 1134)
			
			inventory_ui_default_pos = ui.inv_disabled_position
	
	setup_complete.emit()
