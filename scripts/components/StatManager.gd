class_name StatManager extends CharacterComponent

var final_stats : StatData = StatData.new()
var stat_mods : Array[StatData] = []
var upgrade_mods : Array[StatData] = []

var actives : Array[Upgrade] = []

func _ready() -> void:
	super._ready()
	SignalBus.apply_upgrade.connect(_new_upgrade)

func _physics_process(delta : float) -> void:
	if actives.size() > 0:
		do_actives(delta)

func do_actives(delta : float) -> void:
	for active : Upgrade in actives:
		if not active.has_method("activate_effect"): continue
		active.activate_effect(delta)

func clear_actives() -> void:
	actives.clear()

func clear_mods() -> void:
	stat_mods.clear()
	_update_stats()

func _update_stats() -> void:
	final_stats = StatData.new()
	for stat_data in stat_mods:
		_apply_mod(stat_data)
	for stat_data in upgrade_mods:
		_apply_mod(stat_data)

func _apply_mod(stat_data : StatData) -> void:
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
	final_stats.mine_strength += stat_data.mine_strength
	final_stats.swing_speed = stat_data.swing_speed if stat_data.swing_speed != 0.3 else final_stats.swing_speed
	final_stats.swing_speed_offset -= stat_data.swing_speed_offset

func _add_mod(data : StatData) -> void:
	stat_mods.append(data)
	_update_stats()
	
func _add_upgrade_mod(data : StatData) -> void:
	upgrade_mods.append(data)
	_update_stats()

func _new_upgrade(upgrade : Upgrade) -> void:
	_add_upgrade_mod(upgrade.stat_data)
	if upgrade.type != Upgrade.UpgradeType.ACTIVE: return
	
	actives.append(upgrade)
