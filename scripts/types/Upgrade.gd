class_name Upgrade extends Resource

enum UpgradeType {
	PASSIVE,
	ACTIVE,
}

@export var upgrade_id : int
@export var texture : Texture2D
@export var display_name : String
@export var details : String
@export var type : UpgradeType

@export var stat_data : StatData

func activate_effect() -> void:
	pass
