class_name PlayerGUI extends Control

@export var inventory_ui : InventoryUI
@export var crafting_ui : CraftingUI
@export var inventory_component : InventoryComponent
@export var crafting_component : CraftingComponent
@export var player : Player
@export var health_component : HealthComponent
@export var xp_component : XPComponent

@export var xp_bar : TextureProgressBar
@export var health_bar : TextureProgressBar
var current_tween : Tween

func _ready() -> void:
	inventory_ui.inventory_component = inventory_component
	inventory_ui.set_up()

	crafting_ui.inventory_component = inventory_component
	crafting_ui.crafting_component = crafting_component
	crafting_ui.set_up()
	
	_health_update(health_component.max_health, health_component.max_health )
	health_component.health_changed.connect(_health_update)
	xp_component.xp_changed.connect(_xp_update)

func _health_update(current : float, max : float) -> void:
	if current_tween and current_tween.is_running():
		current_tween.kill()

	health_bar.max_value = max
	current_tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)
	current_tween.tween_property(health_bar, "value", current, 0.5)

func _xp_update(current : float, max : float) -> void:
	if current_tween and current_tween.is_running():
		current_tween.kill()

	xp_bar.max_value = max
	current_tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)
	current_tween.tween_property(xp_bar, "value", current, 0.5)
