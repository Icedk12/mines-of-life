class_name CraftingComponent extends CharacterComponent

signal crafting_updated

@export var inventory_component : InventoryComponent
@export var station_check_radius : int = 3 ## Radius in tiles around the player to check for crafting stations
var last_nearby_stations : Array[int] = []

func _process(_delta: float) -> void:
	if character and character.is_inside_tree():
		_check_station_changes()

func _check_station_changes() -> void:
	var current_stations := get_nearby_crafting_requirements()
	
	if current_stations != last_nearby_stations:
		last_nearby_stations = current_stations
		crafting_updated.emit()

## Returns an array of CraftingRequirement.Block enum values found near the character
func get_nearby_crafting_requirements() -> Array[int]:
	var nearby : Array[int] = [CraftingRequirement.Block.NONE]
	
	if character == null or character.level == null or character.level.level_generator == null:
		return nearby

	var level_generator = character.level.level_generator
	if level_generator.tilemap == null:
		return nearby

	var tilemap : TileMapLayer = level_generator.tilemap
	var player_tile_pos : Vector2i = tilemap.local_to_map(tilemap.to_local(character.global_position))

	for x in range(player_tile_pos.x - station_check_radius, player_tile_pos.x + station_check_radius + 1):
		for y in range(player_tile_pos.y - station_check_radius, player_tile_pos.y + station_check_radius + 1):
			var check_pos := Vector2i(x, y)
			if tilemap.get_cell_source_id(check_pos) == -1:
				continue

			var tile_data : TileData = tilemap.get_cell_tile_data(check_pos)
			if tile_data:
				var req_value : int = tile_data.get_custom_data("craft_req")
				if req_value != CraftingRequirement.Block.NONE and not nearby.has(req_value):
					nearby.append(req_value)

	return nearby

## Checks if the player meets both station and ingredient requirements for a recipe
func can_craft(recipe : CraftingRecipe) -> bool:
	if recipe == null or inventory_component == null:
		return false

	if recipe.crafting_requirement != CraftingRequirement.Block.NONE:
		var nearby_stations := get_nearby_crafting_requirements()
		if not nearby_stations.has(recipe.crafting_requirement):
			return false

	for i in range(recipe.input_item_ids.size()):
		var id : int = recipe.input_item_ids[i]
		var amount : int = recipe.input_amounts[i] if i < recipe.input_amounts.size() else 1
		if not inventory_component.has_item(id, amount):
			return false

	if not inventory_component.has_space_for(recipe.output_item_id, recipe.output_amount):
		return false

	return true

## Crafts the item: removes ingredients and adds the output to inventory
func craft(recipe : CraftingRecipe) -> bool:
	if not can_craft(recipe):
		return false

	for i in range(recipe.input_item_ids.size()):
		var id : int = recipe.input_item_ids[i]
		var amount : int = recipe.input_amounts[i] if i < recipe.input_amounts.size() else 1
		inventory_component.remove_item_by_id(id, amount)

	crafting_updated.emit()
	return true
