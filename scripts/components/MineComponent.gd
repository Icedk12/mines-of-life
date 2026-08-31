class_name MineComponent
extends CharacterComponent

@export_group("Components")
@export var stat_manager : StatManager
@export var inventory_component : InventoryComponent
@export var sprite_modifier : SpriteModifierComponent ##67
@export var selection_component : SelectionBoxComponent
@export var camera : ShakeableCamera2D
@export var audio_source : AudioSourceComponent
@export var xp_component : XPComponent

@export_group("Mining")
@export var max_mining_distance : float = 40.0
@export var mine_strength : int = 1
@export var hit_amount : int = 1
@export var tile_damage_component : TileDamageComponent
@export var cd_timer : Timer
@export var trauma : float = 0.45

@export_group("Combat")
@export var attack_damage : float = 1.0
@export var attack_knockback_force : float = 120.0
@export var enemy_collision_mask : int = 2 ## Physics layer of enemies

var level_generator : LevelGenerator
var is_holding_left_click: bool = false

func _process(_delta: float) -> void:
	update_selection()
	if is_holding_left_click:
		mine()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_holding_left_click = event.pressed
		if is_holding_left_click:
			get_viewport().set_input_as_handled()

func update_selection() -> void:
	if not level_generator and character and character.level:
		level_generator = character.level.level_generator

	if not level_generator or not level_generator.tilemap:
		return

	var mouse_pos = character.get_global_mouse_position()
	
	# Cursor
	var tile_pos = level_generator.tilemap.local_to_map(mouse_pos)
	selection_component.selected_tile_global_pos = level_generator.tilemap.to_global(tile_pos * 8) + Vector2(4, 4)

func mine() -> bool:
	# Check if the cooldown timer is actively running
	if cd_timer and cd_timer.time_left > 0:
		return false

	if not level_generator or not level_generator.tilemap:
		return false

	var mouse_pos = character.get_global_mouse_position()
	if character.global_position.distance_to(mouse_pos) > max_mining_distance:
		return false

	# get enemy at cursor if there is one also line 67 rofl (no longer applicable) (nvm im the goat)
	var enemy := _get_enemy_at(mouse_pos)
	if enemy:
		return _attack_enemy(enemy)

	var tile_pos = level_generator.tilemap.local_to_map(mouse_pos)
	if level_generator.tilemap.get_cell_source_id(tile_pos) == -1:
		return false

	var result = level_generator.damage_tile(tile_pos, (hit_amount + stat_manager.final_stats.mine_damage_offset) * stat_manager.final_stats.mine_damage_modifier, mine_strength + stat_manager.final_stats.mine_strength)
	if result.is_empty() or result.get("blocked", false):
		return false

	# Mining
	if result.get("broken", false):
		if inventory_component and result.block_id != -1:
			var block_data : BlockData = BlockDatabase.get_block_by_id(result.block_id)
		
			# No extra drops
			if block_data.block_only:
				var mined_item := ItemDatabase.get_item_by_block_id(result.block_id)
				if mined_item:
					inventory_component.add_item_by_id(mined_item.item_id, 1)
			
			# Extra drops
			else:
				for i in range(block_data.drop_ids.size()):
					var item_id : int = block_data.drop_ids[i]
					var amount : int = block_data.drop_amount[i] if i < block_data.drop_amount.size() else 1
					var scarcity : int = block_data.drop_scarcity[i] if i < block_data.drop_scarcity.size() else 0
					
					if scarcity > 0 and randi_range(1, scarcity) != 1:
						continue
					
					var drop_item := ItemDatabase.get_item_by_id(item_id)
					if drop_item:
						inventory_component.add_item_by_id(drop_item.item_id, amount)
		if tile_damage_component:
			tile_damage_component.clear()
		if audio_source:
			audio_source.play_sound(result.block_data.hit_sounds)
	else:
		if tile_damage_component:
			tile_damage_component.play_hit(tile_pos, result.hits, result.max_hits, result.block_data)
		if audio_source:
			audio_source.play_sound(result.block_data.hit_sounds)
	
	var mine_direction : Vector2 = character.global_position.direction_to(mouse_pos)
	if sprite_modifier:
		sprite_modifier._mining_tween(mine_direction)

	camera.add_trauma(trauma * stat_manager.final_stats.swing_speed)
	camera.shake()
	cd_timer.wait_time = stat_manager.final_stats.swing_speed
	if cd_timer:
		cd_timer.start()

	return true

## Gets enemies at a position
func _get_enemy_at(world_pos: Vector2) -> Node:
	var space_state := character.get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = world_pos
	params.collision_mask = enemy_collision_mask
	params.collide_with_bodies = true
	params.collide_with_areas = false

	for result in space_state.intersect_point(params, 8):
		if result.collider.is_in_group("enemies"):
			return result.collider
	return null

func _attack_enemy(enemy: Node) -> bool:
	if enemy.has_method("get_health_component"):
		var hc : HealthComponent = enemy.get_health_component()
		if hc:
			if not hc.died.is_connected(on_kill):
				hc.died.connect(on_kill)

			hc.take_damage(
				(attack_damage + stat_manager.final_stats.damage_offset) * stat_manager.final_stats.damage_modifier,
				enemy.global_position.direction_to(enemy.global_position + (enemy.global_position - character.global_position)),
				attack_knockback_force
			)

	if sprite_modifier:
		sprite_modifier._mining_tween(character.global_position.direction_to(enemy.global_position))

	camera.add_trauma(trauma * stat_manager.final_stats.swing_speed)
	camera.shake()
	cd_timer.wait_time = stat_manager.final_stats.swing_speed
	cd_timer.start()
	return true

func on_kill(xp : float) -> void:
	xp_component.add_xp(xp)
