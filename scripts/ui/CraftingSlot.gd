class_name CraftingSlot extends PanelContainer

@export var icon_rect : TextureRect
@export var count_label : InventoryLabel
@export var hover_label : Label

var recipe : CraftingRecipe
var crafting_component : CraftingComponent
var inventory_component : InventoryComponent

var _pending_item_id : int = -1
var _pending_amount : int = 0
var is_hovered : bool

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _process(_delta: float) -> void:
	if is_hovered and hover_label and hover_label.visible:
		hover_label.global_position = get_global_mouse_position() - Vector2(hover_label.size.x - 150, 0)

func _on_mouse_entered() -> void:
	is_hovered = true
	_update_hover_label()

func _update_hover_label() -> void:
	if not recipe or hover_label == null:
		return

	var item := ItemDatabase.get_item_by_id(recipe.output_item_id)
	if item:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		hover_label.text = str(item.item_name + ": " + recipe.get_recipe_str())
		hover_label.global_position = get_global_mouse_position()
		hover_label.visible = true
	else:
		hover_label.visible = false

func _on_mouse_exited() -> void:
	is_hovered = false
	if hover_label:
		hover_label.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func bind(_recipe: CraftingRecipe, _crafting_component: CraftingComponent, _inventory_component: InventoryComponent) -> void:
	recipe = _recipe
	crafting_component = _crafting_component
	inventory_component = _inventory_component
	refresh()

func refresh() -> void:
	if not recipe:
		return
	var item := ItemDatabase.get_item_by_id(recipe.output_item_id)
	if item == null:
		return

	icon_rect.texture = item.icon
	count_label.stack_size = str(item.stack_size)
	count_label.set_text_value(str(recipe.output_amount) if recipe.output_amount > 1 else "")

	var craftable := crafting_component.can_craft(recipe)
	modulate.a = 1.0 if craftable else 0.4
	mouse_filter = Control.MOUSE_FILTER_STOP #if craftable else Control.MOUSE_FILTER_IGNORE

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		_try_craft_and_drag()

func _try_craft_and_drag() -> void:
	if not crafting_component.craft(recipe):
		return

	_pending_item_id = recipe.output_item_id
	_pending_amount = recipe.output_amount

	var data := {
		"is_craft": true,
		"item_id": _pending_item_id,
		"amount": _pending_amount,
	}
	
	if hover_label:
		hover_label.visible = false
		
	force_drag(data, _make_preview(_pending_item_id, _pending_amount))

## Fires when the drag started above ends, whether it landed on a slot or not.
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if _pending_item_id == -1:
			return
		if not get_viewport().gui_is_drag_successful():
			inventory_component.add_item_by_id(_pending_item_id, _pending_amount)
		_pending_item_id = -1
		_pending_amount = 0

func _make_preview(item_id: int, amount: int) -> Control:
	var item := ItemDatabase.get_item_by_id(item_id)
	var preview := TextureRect.new()
	if item:
		preview.texture = item.icon
	preview.custom_minimum_size = Vector2(48, 48)
	preview.modulate.a = 0.8
	return preview
