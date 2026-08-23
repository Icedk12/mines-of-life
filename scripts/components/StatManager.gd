class_name StatManager extends CharacterComponent

var final_stats : StatData = StatData.new()
var stat_mods : Array[StatData] = []

func clear_mods() -> void:
	stat_mods.clear()
	_update_stats()

func _update_stats() -> void:
	# Always start from fresh baseline stats
	final_stats = StatData.new()

	for stat_data : StatData in stat_mods:
		final_stats.health_modifier += (stat_data.health_modifier - 1.0)
		final_stats.health_offset += stat_data.health_offset

		final_stats.speed_modifier += (stat_data.speed_modifier - 1.0)
		final_stats.speed_offset += stat_data.speed_offset

		final_stats.jump_modifier += (stat_data.jump_modifier - 1.0)
		final_stats.jump_offset += stat_data.jump_offset

		final_stats.damage_modifier += (stat_data.damage_modifier - 1.0)
		final_stats.damage_offset += stat_data.damage_offset

		final_stats.mine_damage_modifier += (stat_data.mine_damage_modifier - 1.0)
		final_stats.mine_damage_offset += stat_data.mine_damage_offset

func _add_mod(data : StatData) -> void:
	stat_mods.append(data)
	_update_stats()
