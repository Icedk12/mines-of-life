class_name UpgradePanelHolder extends Panel

var choosing : bool = false
var current_choices : Array[Upgrade] = []

func _ready() -> void:
	SignalBus.draw_upgrades.connect(draw_hand)
	
	$UpgradeChoice1.gui_input.connect(_on_choice_gui_input.bind(0))
	$UpgradeChoice2.gui_input.connect(_on_choice_gui_input.bind(1))
	$UpgradeChoice3.gui_input.connect(_on_choice_gui_input.bind(2))

func _on_choice_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if index < current_choices.size():
			choose(current_choices[index])

func randomise_upgrades() -> void:
	var available_upgrades = UpgradeDatabase.upgrades.duplicate()
	available_upgrades.shuffle()
	
	current_choices.clear()
	for i in range(min(3, available_upgrades.size())):
		current_choices.append(available_upgrades[i])
	
	var nodes = [$UpgradeChoice1, $UpgradeChoice2, $UpgradeChoice3]
	
	for i in range(nodes.size()):
		if i < current_choices.size():
			var u: Upgrade = current_choices[i]
			nodes[i].visible = true
			nodes[i].get_node("Image").texture = u.texture
			nodes[i].get_node("Name").text = u.display_name
			nodes[i].get_node("Desc").text = u.details
		else:
			nodes[i].visible = false

func choose(upgrade: Upgrade) -> void:
	SignalBus.apply_upgrade.emit(upgrade)
	visible = false

func draw_hand() -> void:
	visible = true
	randomise_upgrades()
