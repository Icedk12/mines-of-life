class_name StatManager extends CharacterComponent

var final_stats : StatData = StatData.new()
var stat_mods : Array[StatData] = []

func _update_stats() -> void:
	for stat_data : StatData in stat_mods:
		final_stats.health_modifier += stat_data.health_modifier
		final_stats.health_offset += stat_data.health_offset

		final_stats.speed_modifier += stat_data.speed_modifier
		final_stats.speed_offset += stat_data.speed_offset

		final_stats.jump_modifier += stat_data.jump_modifier
		final_stats.jump_offset += stat_data.jump_offset

		final_stats.damage_modifier += stat_data.damage_modifier
		final_stats.damage_offset += stat_data.damage_offset

		final_stats.mine_damage_modifier += stat_data.mine_damage_modifier
		final_stats.mine_damage_offset += stat_data.mine_damage_offset

func _add_mod(data : StatData) -> void:
	stat_mods.append(data)
	_update_stats()
